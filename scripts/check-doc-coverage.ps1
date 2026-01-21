##############################################################################
# 文档覆盖率检查脚本 (PowerShell 版本)
#
# 用途：检查文档覆盖率，确保代码和功能都有对应文档
# 使用：.\scripts\check-doc-coverage.ps1
#
# 作者：Claude Code
# 版本：v1.0.0
# 更新：2026-01-21
##############################################################################

# 打印函数
function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
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

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

Write-Host "📊 文档覆盖率检查"
Write-Host ""

# 总体统计
$totalChecks = 0
$passedChecks = 0

# 检查插件文档覆盖率
Print-Header "1. 插件文档覆盖率"

$pluginDirs = Get-ChildItem -Path "lib/plugins" -Directory | Where-Object { $_.Name -ne "plugins" }
$pluginCount = $pluginDirs.Count
$docDirs = Get-ChildItem -Path "docs/plugins" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "plugins" }
$docCount = if ($docDirs) { $docDirs.Count } else { 0 }
$pluginReadmeFiles = Get-ChildItem -Path "docs/plugins" -Recurse -Filter "README.md" -ErrorAction SilentlyContinue
$pluginReadmeCount = if ($pluginReadmeFiles) { $pluginReadmeFiles.Count } else { 0 }

Print-Info "插件数量: $pluginCount"
Print-Info "插件文档目录: $docCount"
Print-Info "插件 README: $pluginReadmeCount"

if ($pluginReadmeCount -lt $pluginCount) {
    Print-Warning "部分插件缺少 README 文档"
    $coverage = [math]::Round($pluginReadmeCount * 100 / $pluginCount, 1)
    Print-Info "插件覆盖率: $coverage%"

    # 找出缺少文档的插件
    Write-Host ""
    Print-Info "缺少文档的插件："
    foreach ($pluginDir in $pluginDirs) {
        $pluginName = $pluginDir.Name
        $readmePath = "docs/plugins/$pluginName/README.md"
        if (-not (Test-Path $readmePath)) {
            Write-Host "  - $pluginName"
        }
    }
    $totalChecks++
} else {
    Print-Success "所有插件都有 README 文档"
    $totalChecks++
    $passedChecks++
}

# 检查配置文档覆盖率
Print-Header "2. 配置文档覆盖率"

$configFiles = Get-ChildItem -Path "lib/plugins" -Recurse -Filter "*_settings.dart" -ErrorAction SilentlyContinue
$configCount = if ($configFiles) { $configFiles.Count } else { 0 }
$configDocFiles = Get-ChildItem -Path "lib/plugins" -Recurse -Filter "*_config_docs.md" -ErrorAction SilentlyContinue
$configDocCount = if ($configDocFiles) { $configDocFiles.Count } else { 0 }

Print-Info "配置模型数量: $configCount"
Print-Info "配置文档数量: $configDocCount"

if ($configCount -gt 0) {
    if ($configDocCount -lt $configCount) {
        Print-Warning "部分配置缺少文档"
        $coverage = [math]::Round($configDocCount * 100 / $configCount, 1)
        Print-Info "配置文档覆盖率: $coverage%"

        # 找出缺少文档的配置
        Write-Host ""
        Print-Info "缺少文档的配置："
        foreach ($configFile in $configFiles) {
            $pluginName = ($configFile.Directory.Parent).Name
            $configName = $configFile.BaseName -replace "_settings", ""
            $configDoc = "lib/plugins/$pluginName/config/${configName}_config_docs.md"
            if (-not (Test-Path $configDoc)) {
                Write-Host "  - $pluginName/$configName"
            }
        }
        $totalChecks++
    } else {
        Print-Success "所有配置都有文档"
        $totalChecks++
        $passedChecks++
    }
} else {
    Print-Info "没有找到配置文件"
}

# 检查规范文档完整性
Print-Header "3. 规范文档完整性"

$requiredRules = @(
    "CODE_STYLE_RULES.md",
    "TESTING_RULES.md",
    "GIT_COMMIT_RULES.md",
    "ERROR_HANDLING_RULES.md",
    "VERSION_CONTROL_RULES.md",
    "PLUGIN_CONFIG_SPEC.md",
    "JSON_CONFIG_RULES.md",
    "DOCUMENTATION_NAMING_RULES.md",
    "FILE_ORGANIZATION_RULES.md"
)

$missingRules = 0
foreach ($rule in $requiredRules) {
    $rulePath = ".claude/rules/$rule"
    if (-not (Test-Path $rulePath)) {
        Print-Error "缺少规范: $rule"
        $missingRules++
    }
}

if ($missingRules -eq 0) {
    Print-Success "所有必需的规范文档都存在"
    $totalChecks++
    $passedChecks++
} else {
    Print-Warning "缺少 $missingRules 个规范文档"
    $totalChecks++
}

# 检查技术规范文档
Print-Header "4. 技术规范文档"

$specDirs = @(
    ".kiro/specs/platform-services",
    ".kiro/specs/plugin-platform",
    ".kiro/specs/external-plugin-system",
    ".kiro/specs/internationalization",
    ".kiro/specs/web-platform-compatibility"
)

foreach ($specDir in $specDirs) {
    if (Test-Path $specDir) {
        $specName = Split-Path $specDir -Leaf
        $hasRequirements = Test-Path "$specDir/requirements.md"
        $hasDesign = Test-Path "$specDir/design.md"
        $hasTasks = Test-Path "$specDir/tasks.md"

        if ($hasRequirements -and $hasDesign -and $hasTasks) {
            Print-Success "$specName`: 规范完整（requirements, design, tasks）"
            $totalChecks++
            $passedChecks++
        } else {
            Print-Warning "$specName`: 规范不完整"
            if (-not $hasRequirements) { Write-Host "  - 缺少 requirements.md" }
            if (-not $hasDesign) { Write-Host "  - 缺少 design.md" }
            if (-not $hasTasks) { Write-Host "  - 缺少 tasks.md" }
            $totalChecks++
        }
    }
}

# 检查平台服务文档
Print-Header "5. 平台服务文档"

$platformServiceDocs = @(
    "docs/platform-services/README.md",
    "docs/platform-services/quick-start.md",
    "docs/platform-services/structure.md",
    "docs/guides/platform-services-user-guide.md"
)

foreach ($doc in $platformServiceDocs) {
    if (Test-Path $doc) {
        Print-Success "存在: $(Split-Path $doc -Leaf)"
        $totalChecks++
        $passedChecks++
    } else {
        Print-Warning "缺失: $doc"
        $totalChecks++
    }
}

# 检查用户指南
Print-Header "6. 用户指南文档"

$userGuides = @(
    "docs/guides/getting-started.md",
    "docs/guides/internal-plugin-development.md",
    "docs/guides/external-plugin-development.md"
)

foreach ($guide in $userGuides) {
    if (Test-Path $guide) {
        Print-Success "存在: $(Split-Path $guide -Leaf)"
        $totalChecks++
        $passedChecks++
    } else {
        Print-Warning "缺失: $guide"
        $totalChecks++
    }
}

# 输出总结
Print-Header "检查总结"

Write-Host "总检查项: $totalChecks"
Write-Host "通过数量: $passedChecks"
Write-Host "失败数量: $($totalChecks - $passedChecks)"

if ($passedChecks -eq $totalChecks) {
    $coverage = "100%"
    Print-Success "文档覆盖率: $coverage"
    Write-Host ""
    Print-Success "所有检查通过！"
    exit 0
} else {
    $coverage = [math]::Round($passedChecks * 100 / $totalChecks, 1)
    Print-Warning "文档覆盖率: $coverage%"
    Write-Host ""
    Print-Info "请根据上述提示补充缺失的文档"
    exit 1
}
