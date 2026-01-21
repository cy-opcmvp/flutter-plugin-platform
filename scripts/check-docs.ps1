##############################################################################
# 文档变更检查脚本 (PowerShell 版本)
#
# 用途：在 git commit 前检查代码变更是否伴随相应的文档更新
# 使用：在 git hooks 中调用，或手动运行 .\scripts\check-docs.ps1
#
# 作者：Claude Code
# 版本：v1.0.0
# 更新：2026-01-21
##############################################################################

param(
    [Parameter(Position=0)]
    [ValidateSet("staged", "committed")]
    [string]$Mode = "staged"
)

# 颜色输出函数
function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# 检查是否在 git 仓库中
function Test-GitRepo {
    $result = git rev-parse --git-dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Print-Error "当前目录不是 git 仓库"
        exit 1
    }
}

# 获取变更的文件
function Get-ChangedFiles {
    param([string]$DiffTarget = "HEAD")

    $files = git diff --name-only --diff-filter=d $DiffTarget 2>&1 |
            Where-Object { $_ -notlike "build/*" -and $_ -notlike ".dart_tool/*" }
    return $files
}

# 获取暂存区的变更文件
function Get-StagedFiles {
    $files = git diff --cached --name-only --diff-filter=d 2>&1 |
            Where-Object { $_ -notlike "build/*" -and $_ -notlike ".dart_tool/*" }
    return $files
}

# 检查插件代码变更
function Test-PluginChanges {
    param([string[]]$ChangedFiles)

    Print-Header "检查插件代码与文档同步"

    $pluginCodeChanged = $false
    $pluginDocsUpdated = $false
    $pluginNames = @()

    # 检查是否有插件代码变更
    foreach ($file in $ChangedFiles) {
        if ($file -like "lib/plugins/*" -and $file -notlike "*.md") {
            $pluginCodeChanged = $true
            # 提取插件名称
            $pluginName = ($file -split '/')[2]
            if ($pluginNames -notcontains $pluginName) {
                $pluginNames += $pluginName
            }
        }
    }

    # 检查是否有插件文档变更
    foreach ($file in $ChangedFiles) {
        if ($file -like "docs/plugins/*" -or $file -like "lib/plugins/*/config/*_config_docs.md") {
            $pluginDocsUpdated = $true
            break
        }
    }

    if ($pluginCodeChanged -and -not $pluginDocsUpdated) {
        Print-Warning "检测到插件代码变更，但未更新相关文档"
        Write-Host ""
        Write-Host "涉及的插件："
        foreach ($plugin in $pluginNames) {
            Write-Host "  - $plugin"
            Write-Host "    可能需要更新的文档："
            Write-Host "      • docs/plugins/$plugin/README.md"
            $configDoc = "lib/plugins/$plugin/config/$plugin" + "_config_docs.md"
            if (Test-Path $configDoc) {
                Write-Host "      • $configDoc"
            }
        }
        Write-Host ""
        Print-Info "如果这是不需要更新文档的变更（如 bug 修复），请忽略此警告"
        return $false
    } else {
        Print-Success "插件代码与文档同步检查通过"
        return $true
    }
}

# 检查配置文件变更
function Test-ConfigChanges {
    param([string[]]$ChangedFiles)

    Print-Header "检查配置文件与文档同步"

    $configChanged = $false
    $configDocChanged = $false

    foreach ($file in $ChangedFiles) {
        # 检查是否修改了配置默认值
        if ($file -like "lib/plugins/*/config/*_config_defaults.dart") {
            $configChanged = $true
            $pluginName = ($file -split '/')[2]
            Print-Info "插件 $pluginName 的配置默认值已变更"
        }

        # 检查是否更新了配置文档
        if ($file -like "lib/plugins/*/config/*_config_docs.md") {
            $configDocChanged = $true
        }
    }

    if ($configChanged -and -not $configDocChanged) {
        Print-Warning "配置文件已变更，但配置文档未更新"
        Print-Info "请检查是否需要更新相应的 *_config_docs.md 文件"
        return $false
    } else {
        Print-Success "配置文件与文档同步检查通过"
        return $true
    }
}

# 检查平台服务变更
function Test-PlatformServiceChanges {
    param([string[]]$ChangedFiles)

    Print-Header "检查平台服务文档同步"

    $serviceChanged = $false
    $serviceDocChanged = $false

    foreach ($file in $ChangedFiles) {
        # 检查是否修改了平台服务代码
        if ($file -like "lib/core/services/*" -and $file -notlike "*.md") {
            $serviceChanged = $true
            Print-Info "检测到平台服务代码变更: $file"
        }

        # 检查是否更新了服务文档
        if ($file -like "docs/platform-services/*" -or $file -eq "docs/guides/platform-services-user-guide.md") {
            $serviceDocChanged = $true
        }
    }

    if ($serviceChanged -and -not $serviceDocChanged) {
        Print-Warning "平台服务代码已变更，但相关文档未更新"
        Print-Info "可能需要更新的文档："
        Write-Host "  • docs/platform-services/README.md"
        Write-Host "  • docs/guides/platform-services-user-guide.md"
        return $false
    } else {
        Print-Success "平台服务与文档同步检查通过"
        return $true
    }
}

# 检查国际化变更
function Test-I18nChanges {
    param([string[]]$ChangedFiles)

    Print-Header "检查国际化文件同步"

    $arbsChanged = $false
    $zhChanged = $false
    $enChanged = $false

    foreach ($file in $ChangedFiles) {
        if ($file -eq "lib/l10n/app_zh.arb") {
            $zhChanged = $true
            $arbsChanged = $true
        }
        if ($file -eq "lib/l10n/app_en.arb") {
            $enChanged = $true
            $arbsChanged = $true
        }
    }

    if ($arbsChanged) {
        if ($zhChanged -and -not $enChanged) {
            Print-Warning "app_zh.arb 已变更，但 app_en.arb 未同步"
            return $false
        } elseif ($enChanged -and -not $zhChanged) {
            Print-Warning "app_en.arb 已变更，但 app_zh.arb 未同步"
            return $false
        }
    }

    Print-Success "国际化文件同步检查通过"
    return $true
}

# 检查 CHANGELOG
function Test-Changelog {
    param([string[]]$ChangedFiles)

    Print-Header "检查 CHANGELOG.md"

    $hasSignificantChanges = $false

    foreach ($file in $ChangedFiles) {
        # 新增插件
        if ($file -like "lib/plugins/*" -and $file -like "*_plugin.dart") {
            $hasSignificantChanges = $true
            Print-Info "检测到新插件: $file"
        }

        # 新增服务
        if ($file -like "lib/core/services/*/*_service.dart") {
            $hasSignificantChanges = $true
            Print-Info "检测到新服务: $file"
        }
    }

    if ($hasSignificantChanges) {
        if ("CHANGELOG.md" -notin $ChangedFiles) {
            Print-Warning "检测到重要功能变更，但 CHANGELOG.md 未更新"
            Print-Info "如果这是不应记录到 CHANGELOG 的变更（如重构），请忽略"
            return $false
        }
    }

    Print-Success "CHANGELOG.md 检查通过"
    return $true
}

# 主函数
function Main {
    Print-Header "📚 文档变更检查工具 (PowerShell)"

    # 检查 git 仓库
    Test-GitRepo

    # 获取要检查的文件
    Print-Info "检查模式: $Mode"

    $filesToCheck = @()
    if ($Mode -eq "staged") {
        Print-Info "检查暂存区的文件变更..."
        $filesToCheck = Get-StagedFiles
    } elseif ($Mode -eq "committed") {
        Print-Info "检查最近一次提交的变更..."
        $filesToCheck = Get-ChangedFiles "HEAD~1"
    }

    if ($filesToCheck.Count -eq 0) {
        Print-Info "没有检测到文件变更"
        exit 0
    }

    Write-Host "检测到 $($filesToCheck.Count) 个文件变更"
    Write-Host ""

    # 执行各项检查
    $totalChecks = 0
    $failedChecks = 0

    if (-not (Test-PluginChanges $filesToCheck)) { $failedChecks++ }
    $totalChecks++

    if (-not (Test-ConfigChanges $filesToCheck)) { $failedChecks++ }
    $totalChecks++

    if (-not (Test-PlatformServiceChanges $filesToCheck)) { $failedChecks++ }
    $totalChecks++

    if (-not (Test-I18nChanges $filesToCheck)) { $failedChecks++ }
    $totalChecks++

    if (-not (Test-Changelog $filesToCheck)) { $failedChecks++ }
    $totalChecks++

    # 输出总结
    Print-Header "检查总结"
    Write-Host "总检查数: $totalChecks"
    Write-Host "失败数: $failedChecks"

    if ($failedChecks -gt 0) {
        Write-Host ""
        Print-Warning "部分检查未通过"
        Print-Info "如果确认这些警告可以忽略，可以使用 git commit --no-verify 跳过检查"
        exit 1
    } else {
        Write-Host ""
        Print-Success "所有检查通过！"
        exit 0
    }
}

# 运行主函数
Main
