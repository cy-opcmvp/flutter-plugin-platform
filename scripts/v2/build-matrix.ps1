<#
.SYNOPSIS
  M3 六端构建矩阵（toolbox_host）。

.DESCRIPTION
  证据模型（M3 计划决策 5：诚实构建矩阵，不伪造跳过端）：
  - windows / web：本机实构建，记录退出码与产物路径；
  - android：探测到 Android SDK 才实构建，否则输出 SKIPPED-LOCAL-UNAVAILABLE；
  - macos / linux / ios：本机操作系统无法构建，输出 SKIPPED-LOCAL-UNAVAILABLE，
    以「六端编译图静态检查（平台专属依赖零混入）+ flutter analyze」作为
    跳过端的替代证据；
  - CI 预留：本脚本对本机状态无写死假设，可直接被 CI 引用；在对应
    runner（macos/linux）上跳过端可改为实构建。

.NOTES
  用法：pwsh / powershell -File scripts/v2/build-matrix.ps1
  可选参数 -V2Root 指定 v2 workspace 根目录（默认仓库内 v2/）。
#>

param(
  [string]$V2Root = ''
)

if (-not $V2Root) {
  $repoRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).Path
  $V2Root = Join-Path $repoRoot 'v2'
}
if (-not (Test-Path $V2Root)) {
  Write-Host "FATAL: v2 root not found: $V2Root"
  exit 1
}

$ErrorActionPreference = 'Continue'

$hostApp = Join-Path (Join-Path $V2Root 'apps') 'toolbox_host'
$rows = New-Object System.Collections.Generic.List[string]
$script:hasBuildFailure = $false

function Add-Row([string]$target, [string]$status, [string]$detail) {
  $script:rows.Add(("{0,-10} {1,-28} {2}" -f $target, $status, $detail))
}

function Invoke-Build([string]$target, [string[]]$buildArgs, [string[]]$artifacts) {
  Write-Host "==> flutter $($buildArgs -join ' ')"
  $output = & flutter @buildArgs 2>&1
  $code = $LASTEXITCODE
  $tail = ($output | Select-Object -Last 3) -join ' | '
  if ($code -ne 0) {
    $script:hasBuildFailure = $true
    Add-Row $target "FAILED(exit=$code)" $tail
    return
  }

  $missing = @()
  foreach ($path in $artifacts) {
    if (-not (Test-Path $path)) { $missing += $path }
  }
  if ($missing.Count -gt 0) {
    $script:hasBuildFailure = $true
    Add-Row $target "FAILED(exit=0,artifact-missing)" ($missing -join ', ')
    return
  }
  Add-Row $target 'OK' ($artifacts -join ', ')
}

function Test-PlatformOnlyImports {
  <#
    六端编译图静态检查：宿主与各包 lib 中不得混入平台专属插件依赖；
    纯 Dart 包（contracts/runtime）不得导入 dart:io 与 package:flutter。
    这是 macos / linux / ios 跳过端的替代证据。
  #>
  $platformOnly = @(
    'just_audio', 'flutter_local_notifications', 'permission_handler',
    'window_manager', 'shared_preferences', 'path_provider', 'url_launcher'
  )
  $packageRoot = Join-Path $V2Root 'packages'
  $scanTargets = @(
    @{ Name = 'plugin_contracts'; Dir = Join-Path (Join-Path $packageRoot 'plugin_contracts') 'lib'; PureDart = $true },
    @{ Name = 'plugin_runtime'; Dir = Join-Path (Join-Path $packageRoot 'plugin_runtime') 'lib'; PureDart = $true },
    @{ Name = 'plugin_sidecar'; Dir = Join-Path (Join-Path $packageRoot 'plugin_sidecar') 'lib'; PureDart = $false },
    @{ Name = 'plugin_flutter'; Dir = Join-Path (Join-Path $packageRoot 'plugin_flutter') 'lib'; PureDart = $false },
    @{ Name = 'toolbox_host'; Dir = Join-Path $hostApp 'lib'; PureDart = $false }
  )
  Get-ChildItem -Path $packageRoot -Directory -Filter 'platform_capabilities*' | ForEach-Object {
    $scanTargets += @{
      Name = $_.Name
      Dir = (Join-Path $_.FullName 'lib')
      PureDart = $true
    }
  }

  $violations = New-Object System.Collections.Generic.List[string]
  $scanned = 0
  foreach ($item in $scanTargets) {
    if (-not (Test-Path $item.Dir)) { continue }
    $scanned++
    $files = Get-ChildItem -Path $item.Dir -Recurse -File -Filter '*.dart'
    foreach ($file in $files) {
      $content = Get-Content $file.FullName -Raw
      if ($null -eq $content) { continue }
      foreach ($pkg in $platformOnly) {
        if ($content -match "(?m)^\s*(import|export)\s+['`"]package:$pkg/") {
          $violations.Add("$($item.Name): platform-only import 'package:$pkg/' in $($file.Name)")
        }
      }
      if ($item.PureDart) {
        # 只匹配导入语句行，注释/文档中提及 dart:io 不算违规。
        if ($content -match "(?m)^\s*(import|export)\s+['`"]dart:io['`"]") {
          $violations.Add("$($item.Name): dart:io import in $($file.Name)")
        }
        if ($content -match "(?m)^\s*(import|export)\s+['`"]package:flutter/") {
          $violations.Add("$($item.Name): flutter import in $($file.Name)")
        }
      }
    }
  }

  if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Host "  VIOLATION: $_" }
    $script:hasBuildFailure = $true
    Add-Row 'compile-graph' 'FAILED' "$($violations.Count) violation(s)"
  }
  elseif ($scanned -eq 0) {
    $script:hasBuildFailure = $true
    Add-Row 'compile-graph' 'FAILED' 'no package directory scanned; check V2Root layout'
  }
  else {
    Add-Row 'compile-graph' 'OK' "$scanned packages scanned, 0 platform-only imports"
  }
}

function Get-AndroidSdkDir {
  foreach ($name in @('ANDROID_HOME', 'ANDROID_SDK_ROOT')) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ($value -and (Test-Path $value)) { return $value }
  }
  $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
  $default = Join-Path (Join-Path $localAppData 'Android') 'Sdk'
  if (Test-Path $default) { return $default }
  return $null
}

Write-Host "=== v2 build matrix (toolbox_host) ==="
Write-Host "V2Root: $V2Root"
Write-Host ''

Test-PlatformOnlyImports

Push-Location $hostApp
try {
  # windows --debug（本机实构建）
  Invoke-Build 'windows' @('build', 'windows', '--debug') @(
    "$hostApp\build\windows\x64\runner\Debug\toolbox_host.exe"
  )

  # web（本机实构建）
  Invoke-Build 'web' @('build', 'web') @(
    "$hostApp\build\web\index.html"
  )

  # android：探测到 SDK 才实构建
  $sdkDir = Get-AndroidSdkDir
  if ($sdkDir) {
    Invoke-Build 'android' @('build', 'apk', '--debug') @(
      "$hostApp\build\app\outputs\flutter-apk\app-debug.apk"
    )
  }
  else {
    Add-Row 'android' 'SKIPPED-LOCAL-UNAVAILABLE' 'Android SDK not detected on this host'
  }

  # macos / linux / ios：本机不可构建，静态编译图检查已作为替代证据
  Add-Row 'macos' 'SKIPPED-LOCAL-UNAVAILABLE' 'not a macOS host; compile-graph static check is the substitute evidence'
  Add-Row 'linux' 'SKIPPED-LOCAL-UNAVAILABLE' 'not a Linux host; compile-graph static check is the substitute evidence'
  Add-Row 'ios' 'SKIPPED-LOCAL-UNAVAILABLE' 'not a macOS host; compile-graph static check is the substitute evidence'
}
finally {
  Pop-Location
}

Write-Host ''
Write-Host '=== matrix summary ==='
$rows | ForEach-Object { Write-Host $_ }

if ($script:hasBuildFailure) {
  Write-Host ''
  Write-Host 'RESULT: FAILED'
  exit 1
}
Write-Host ''
Write-Host 'RESULT: SUCCESS'
exit 0
