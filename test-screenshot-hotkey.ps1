# 截图热键功能测试辅助脚本
# 使用方法：.\test-screenshot-hotkey.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  截图热键功能测试助手" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testCases = @(
    @{
        Id = 1
        Name = "热键触发 + ESC取消 + 重复热键"
        Steps = @(
            "1. 按下区域截图热键",
            "2. 等待窗口出现",
            "3. 按 ESC 键取消",
            "4. 等待 2 秒",
            "5. 再次按下热键",
            "6. 按 ESC 取消"
        )
        Expected = "应该看到：📍 [ID] 🔓 截图状态：已解锁（finally 块执行）"
    },
    @{
        Id = 2
        Name = "热键触发 + X按钮取消 + 重复热键"
        Steps = @(
            "1. 按下区域截图热键",
            "2. 等待窗口出现",
            "3. 点击窗口右上角 X 按钮",
            "4. 等待 2 秒",
            "5. 再次按下热键",
            "6. 按 ESC 取消"
        )
        Expected = "应该看到：📍 [ID] 🔓 截图状态：已解锁（finally 块执行）"
    },
    @{
        Id = 3
        Name = "热键触发 + √确认 + 重复热键"
        Steps = @(
            "1. 按下区域截图热键",
            "2. 等待窗口出现",
            "3. 拖动鼠标选择区域",
            "4. 点击 √ 确认按钮",
            "5. 等待截图完成",
            "6. 再次按下热键",
            "7. 按 ESC 取消"
        )
        Expected = "截图成功保存，第2次热键正常工作"
    },
    @{
        Id = 4
        Name = "按钮触发 + ESC取消 + 重复按钮"
        Steps = @(
            "1. 在主界面点击区域截图按钮",
            "2. 等待窗口出现",
            "3. 按 ESC 键取消",
            "4. 等待 2 秒",
            "5. 再次点击按钮",
            "6. 按 ESC 取消"
        )
        Expected = "第2次点击正常工作"
    },
    @{
        Id = 5
        Name = "热键快速连续按下（压力测试）"
        Steps = @(
            "1. 快速连续按下热键 3 次（间隔约 0.5 秒）",
            "2. 等待所有操作完成",
            "3. 按 ESC 取消"
        )
        Expected = "第2、3次热键被阻止，第1次完成后状态解锁"
    },
    @{
        Id = 6
        Name = "热键 + 超时测试"
        Steps = @(
            "1. 按下区域截图热键",
            "2. 不进行任何操作，等待 30 秒超时",
            "3. 观察日志输出",
            "4. 再次按下热键",
            "5. 按 ESC 取消"
        )
        Expected = "超时后状态自动解锁，第2次热键正常工作"
    }
)

Write-Host "可用测试用例：" -ForegroundColor Green
foreach ($testCase in $testCases) {
    Write-Host "  [$($testCase.Id)] $($testCase.Name)" -ForegroundColor Yellow
}

Write-Host ""
$response = Read-Host "选择测试用例 (1-$($testCases.Count))，或输入 'all' 运行所有测试"

if ($response -eq 'all') {
    $selectedTests = $testCases
} else {
    $index = [int]$response - 1
    if ($index -ge 0 -and $index -lt $testCases.Count) {
        $selectedTests = @($testCases[$index])
    } else {
        Write-Host "❌ 无效的选择" -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "准备开始测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 测试准备：" -ForegroundColor Green
Write-Host "1. 确保 Flutter 应用正在运行" -ForegroundColor White
Write-Host "2. 打开控制台查看日志输出" -ForegroundColor White
Write-Host "3. 准备好截图热键（通常是 Ctrl+Shift+A）" -ForegroundColor White
Write-Host ""

$ready = Read-Host "准备好了吗？(y/n)"
if ($ready -ne 'y') {
    Write-Host "❌ 测试取消" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "开始测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($testCase in $selectedTests) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "用例 $($testCase.Id)：$($testCase.Name)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "📝 操作步骤：" -ForegroundColor Green
    foreach ($step in $testCase.Steps) {
        Write-Host "  $step" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "✅ 预期结果：" -ForegroundColor Green
    Write-Host "  $($testCase.Expected)" -ForegroundColor White

    Write-Host ""
    Write-Host "🔍 关键日志检查点：" -ForegroundColor Yellow
    Write-Host "  □ 是否看到：📍 [ID] 🔓 截图状态：已解锁（finally 块执行）" -ForegroundColor White
    Write-Host "  □ 是否看到：📍 [ID] _pollForResultForHotkey() 执行结束" -ForegroundColor White
    Write-Host "  □ 第2次操作是否成功（不显示正在进行中）" -ForegroundColor White

    Write-Host ""
    $continue = Read-Host "完成此用例后，输入 y 继续，或输入 s 跳过"

    if ($continue -eq 's') {
        Write-Host "⏭️  已跳过" -ForegroundColor Yellow
        continue
    }

    Write-Host ""
    Write-Host "请记录测试结果（成功/失败/部分成功）：" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "测试完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 请提供以下信息：" -ForegroundColor Green
Write-Host "1. 每个用例的测试结果（成功/失败）" -ForegroundColor White
Write-Host "2. 失败用例的控制台日志（完整输出）" -ForegroundColor White
Write-Host "3. 观察到的异常行为" -ForegroundColor White
Write-Host ""
Write-Host "💡 提示：将控制台日志复制下来，粘贴给开发者分析" -ForegroundColor Yellow
