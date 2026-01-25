import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/interfaces/i_platform_plugin.dart';
import '../../core/models/plugin_models.dart';
import '../../core/utils/platform_capability_helper.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'models/calculator_settings.dart';
import 'widgets/settings_screen.dart';

/// A simple calculator plugin that demonstrates tool plugin implementation
///
/// 平台支持：
/// - 所有平台: 完整支持（纯 Dart 实现）
class CalculatorPlugin extends PlatformPluginBase {
  late PluginContext _context;

  // Calculator state - shared with the widget
  final CalculatorState calculatorState = CalculatorState();

  // Calculator settings
  CalculatorSettings _settings = CalculatorSettings.defaultSettings();

  @override
  String get id => 'com.example.calculator';

  @override
  String get name => '计算器';

  @override
  String get version => '1.0.0';

  @override
  PluginType get type => PluginType.tool;

  @override
  PluginPlatformCapabilities get platformCapabilities =>
      _platformCapabilities ??= _createPlatformCapabilities();

  static PluginPlatformCapabilities? _platformCapabilities;

  /// 创建平台能力配置
  PluginPlatformCapabilities _createPlatformCapabilities() {
    return PlatformCapabilityHelper.fullySupported(
      pluginId: id,
      description: '支持基本计算功能（纯 Dart 实现）',
      hideIfUnsupported: false,
    );
  }

  @override
  Future<void> initialize(PluginContext context) async {
    _context = context;

    // Load saved settings if available
    final savedSettings = await _context.dataStorage
        .retrieve<Map<String, dynamic>>('calculator_settings');
    if (savedSettings != null) {
      _settings = CalculatorSettings.fromJson(savedSettings);
    }

    // Load saved state if available
    final savedState = await _context.dataStorage
        .retrieve<Map<String, dynamic>>('calculator_state');
    if (savedState != null) {
      calculatorState.display = savedState['display'] ?? '0';
      calculatorState.previousValue = savedState['previousValue'] ?? '';
      calculatorState.operation = savedState['operation'] ?? '';
      calculatorState.waitingForOperand =
          savedState['waitingForOperand'] ?? false;
    }

    // Note: Notifications skipped as we need BuildContext for localization
    // In production, you might want to implement a different notification system
  }

  /// 获取当前设置
  CalculatorSettings get settings => _settings;

  /// 更新设置
  void updateSettings(CalculatorSettings settings) {
    _settings = settings;
    _saveSettings();
  }

  @override
  Future<void> dispose() async {
    await _saveState();
    await _saveSettings();
    // Note: Notifications skipped as we need BuildContext for localization
  }

  @override
  Widget buildUI(BuildContext context) {
    return CalculatorWidget(
      plugin: this,
      state: calculatorState,
      settings: _settings,
      onStateChanged: _saveState,
    );
  }

  /// 构建设置界面
  Widget buildSettingsScreen() {
    return CalculatorSettingsScreen(plugin: this);
  }

  Future<void> _saveState() async {
    final state = {
      'display': calculatorState.display,
      'previousValue': calculatorState.previousValue,
      'operation': calculatorState.operation,
      'waitingForOperand': calculatorState.waitingForOperand,
    };
    await _context.dataStorage.store('calculator_state', state);
  }

  Future<void> _saveSettings() async {
    await _context.dataStorage.store('calculator_settings', _settings.toJson());
  }

  @override
  Future<void> onStateChanged(PluginState state) async {
    switch (state) {
      case PluginState.active:
        break;
      case PluginState.paused:
      case PluginState.inactive:
        await _saveState();
        break;
      case PluginState.error:
        calculatorState.clear();
        break;
      case PluginState.loading:
        break;
    }
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    return {
      'display': calculatorState.display,
      'previousValue': calculatorState.previousValue,
      'operation': calculatorState.operation,
      'waitingForOperand': calculatorState.waitingForOperand,
    };
  }
}

/// Shared calculator state
class CalculatorState {
  String display = '0';
  String previousValue = '';
  String operation = '';
  bool waitingForOperand = false;

  void clear() {
    display = '0';
    previousValue = '';
    operation = '';
    waitingForOperand = false;
  }
}

/// StatefulWidget for calculator UI
class CalculatorWidget extends StatefulWidget {
  final CalculatorPlugin plugin;
  final CalculatorState state;
  final CalculatorSettings settings;
  final VoidCallback onStateChanged;

  const CalculatorWidget({
    super.key,
    required this.plugin,
    required this.state,
    required this.settings,
    required this.onStateChanged,
  });

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  CalculatorState get _state => widget.state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plugin_calculator_name),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => widget.plugin.buildSettingsScreen(),
                ),
              );
            },
            tooltip: l10n.calculator_settings_title,
          ),
        ],
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Show operation indicator
                  if (_state.previousValue.isNotEmpty)
                    Text(
                      _formatNumber(_state.previousValue) +
                          ' ${_state.operation}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 20),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _formatNumber(_state.display),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _buildButtonRow(['C', '±', '%', '÷']),
                _buildButtonRow(['7', '8', '9', '×']),
                _buildButtonRow(['4', '5', '6', '-']),
                _buildButtonRow(['1', '2', '3', '+']),
                _buildButtonRow(['0', '.', '=']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) => _buildButton(button)).toList(),
      ),
    );
  }

  Widget _buildButton(String text) {
    Color backgroundColor;
    Color textColor = Colors.white;

    if (text == 'C' || text == '±' || text == '%') {
      backgroundColor = Colors.grey[600]!;
    } else if (text == '÷' ||
        text == '×' ||
        text == '-' ||
        text == '+' ||
        text == '=') {
      backgroundColor = Colors.orange;
      // Highlight active operation
      if (_state.operation == text && _state.waitingForOperand) {
        backgroundColor = Colors.orange[300]!;
      }
    } else {
      backgroundColor = Colors.grey[800]!;
    }

    return Expanded(
      flex: text == '0' ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.all(1),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(20),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      switch (buttonText) {
        case 'C':
          _clear();
          break;
        case '±':
          _toggleSign();
          break;
        case '%':
          _percentage();
          break;
        case '÷':
        case '×':
        case '-':
        case '+':
          _setOperation(buttonText);
          break;
        case '=':
          _calculate();
          break;
        case '.':
          _addDecimal();
          break;
        default:
          _addDigit(buttonText);
          break;
      }
    });

    widget.onStateChanged();
  }

  void _clear() {
    _state.display = '0';
    _state.previousValue = '';
    _state.operation = '';
    _state.waitingForOperand = false;
  }

  void _toggleSign() {
    if (_state.display != '0') {
      if (_state.display.startsWith('-')) {
        _state.display = _state.display.substring(1);
      } else {
        _state.display = '-${_state.display}';
      }
    }
  }

  void _percentage() {
    final value = double.tryParse(_state.display);
    if (value != null) {
      _state.display = _formatResult(value / 100);
      _state.waitingForOperand = true;
    }
  }

  void _setOperation(String operation) {
    if (_state.previousValue.isNotEmpty && !_state.waitingForOperand) {
      _calculate();
    }

    _state.previousValue = _state.display;
    _state.operation = operation;
    _state.waitingForOperand = true;
  }

  void _calculate() {
    if (_state.previousValue.isEmpty || _state.operation.isEmpty) return;

    final prev = double.tryParse(_state.previousValue);
    final current = double.tryParse(_state.display);

    if (prev == null || current == null) return;

    double result;
    switch (_state.operation) {
      case '+':
        result = prev + current;
        break;
      case '-':
        result = prev - current;
        break;
      case '×':
        result = prev * current;
        break;
      case '÷':
        if (current == 0) {
          final l10n = AppLocalizations.of(context);
          _state.display = l10n?.plugin_calculator_error ?? 'Error';
          _state.previousValue = '';
          _state.operation = '';
          return;
        }
        result = prev / current;
        break;
      default:
        return;
    }

    _state.display = _formatResult(result);
    _state.previousValue = '';
    _state.operation = '';
    _state.waitingForOperand = true;
  }

  String _formatResult(double result) {
    // Handle very large or very small numbers
    if (result.abs() > 1e12 || (result != 0 && result.abs() < 1e-10)) {
      return result.toStringAsExponential(widget.settings.precision);
    }

    if (result == result.toInt()) {
      // 整数：应用千分位分隔符
      return _formatNumber(result.toInt());
    } else {
      // 小数：使用配置的精度
      final precision = widget.settings.precision;
      String str = result.toStringAsFixed(precision);
      // 移除末尾的0
      str = str.replaceAll(RegExp(r'0+$'), '');
      str = str.replaceAll(RegExp(r'\.$'), '');

      // 应用千分位分隔符
      return _formatNumber(str);
    }
  }

  /// 格式化数字字符串，添加千分位分隔符
  String _formatNumber(dynamic number) {
    final String str = number.toString();

    // 分离整数和小数部分
    final parts = str.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    if (!widget.settings.showGroupingSeparator) {
      return str;
    }

    // 处理负号
    String sign = '';
    String absInteger = integerPart;
    if (integerPart.startsWith('-')) {
      sign = '-';
      absInteger = integerPart.substring(1);
    }

    // 添加千分位分隔符
    final formatted = _addGroupingSeparators(absInteger);

    return '$sign$formatted$decimalPart';
  }

  /// 为整数部分添加千分位分隔符
  String _addGroupingSeparators(String integer) {
    final buffer = StringBuffer();
    int count = 0;

    for (int i = integer.length - 1; i >= 0; i--) {
      buffer.write(integer[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }

    return buffer.toString().split('').reversed.join('');
  }

  void _addDigit(String digit) {
    if (_state.waitingForOperand) {
      _state.display = digit;
      _state.waitingForOperand = false;
    } else {
      // Limit display length
      if (_state.display.length < 15) {
        _state.display = _state.display == '0' ? digit : _state.display + digit;
      }
    }
  }

  void _addDecimal() {
    if (_state.waitingForOperand) {
      _state.display = '0.';
      _state.waitingForOperand = false;
    } else if (!_state.display.contains('.')) {
      _state.display += '.';
    }
  }
}
