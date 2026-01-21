##############################################################################
# 文档链接有效性检查脚本 (PowerShell 版本)
#
# 用途：检查 Markdown 文档中的相对链接是否有效
# 使用：.\scripts\check-doc-links.ps1
#
# 作者：Claude Code
# 版本：v1.0.0
# 更新：2026-01-21
##############################################################################

# 统计变量
$totalLinks = 0
$invalidLinks = 0

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

function Print-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

Write-Host "🔗 检查文档链接有效性"
Write-Host ""

# 检查函数
function Test-LinksInFile {
    param([string]$File)

    $content = Get-Content $File -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return
    }

    # 正则表达式匹配 Markdown 链接
    $linkPattern = '\[.*?\]\(([^)]+)\)'

    # 提取所有链接
    $matches = [regex]::Matches($content, $linkPattern)

    foreach ($match in $matches) {
        $link = $match.Groups[1].Value

        # 排除外部链接
        if ($link -match '^https?://') {
            continue
        }
        if ($link -match '^mailto:') {
            continue
        }

        # 只检查相对链接
        if ($link -match '^\.\./|^\./|^[^/]') {
            $totalLinks++

            # 解析相对路径
            $fileDir = Split-Path $File -Parent
            $targetFile = Join-Path $fileDir $link

            # 处理带 #anchor 的链接
            if ($link -match '#') {
                $targetFile = $link.Split('#')[0]
                $targetFile = Join-Path $fileDir $targetFile
            }

            # 检查目标文件是否存在
            if (-not (Test-Path $targetFile)) {
                Print-Error "$File`: 无效链接 $link"
                $invalidLinks++
            }
        }
    }
}

# 检查所有 Markdown 文档
Print-Header "检查文档链接"

# 检查主要文档目录
$docs = Get-ChildItem -Path "docs", ".claude", ".kiro" -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue
foreach ($doc in $docs) {
    Test-LinksInFile $doc.FullName
}

# 检查插件 README
$pluginReadmes = Get-ChildItem -Path "lib/plugins" -Recurse -Filter "README.md" -File -ErrorAction SilentlyContinue
foreach ($readme in $pluginReadmes) {
    Test-LinksInFile $readme.FullName
}

# 输出结果
Print-Header "检查结果"

Write-Host "总链接数: $totalLinks"
Write-Host "无效链接: $invalidLinks"

if ($invalidLinks -eq 0) {
    Print-Success "所有链接都有效！"
    exit 0
} else {
    Print-Error "发现 $invalidLinks 个无效链接"
    Write-Host ""
    Print-Info "请修复上述无效链接后重新检查"
    exit 1
}
