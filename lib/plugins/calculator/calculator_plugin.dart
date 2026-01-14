import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A simple calculator plugin that demonstrates tool plugin implementation
class CalculatorPlugin implements IPlugin {
  late PluginContext _context;
  
  // Calculator state - shared with the widget
  final CalculatorState calculatorState = CalculatorState();

  @override
  String get id => 'com.example.calculator';

  @override
  String get name => 'Calculator';

  @override
  String get version => '1.0.0';

  @override
  PluginType get type => PluginType.tool;

  @override
  Future<void> initialize(PluginContext context) async {
    _context = context;

    // Load saved state if available
    final savedState = await _context.dataStorage.retrieve<Map<String, dynamic>>('calculator_state');
    if (savedState != null) {
      calculatorState.display = savedState['display'] ?? '0';
      calculatorState.previousValue = savedState['previousValue'] ?? '';
      calculatorState.operation = savedState['operation'] ?? '';
      calculatorState.waitingForOperand = savedState['waitingForOperand'] ?? false;
    }

    // Note: Notifications skipped as we need BuildContext for localization
    // In production, you might want to implement a different notification system
  }

  @override
  Future<void> dispose() async {
    await _saveState();
    // Note: Notifications skipped as we need BuildContext for localization
  }

  @override
  Widget buildUI(BuildContext context) {
    return CalculatorWidget(
      state: calculatorState,
      onStateChanged: _saveState,
    );
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
  final CalculatorState state;
  final VoidCallback onStateChanged;

  const CalculatorWidget({
    super.key,
    required this.state,
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
                      '${_state.previousValue} ${_state.operation}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 20,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _state.display,
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
    } else if (text == '÷' || text == '×' || text == '-' || text == '+' || text == '=') {
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
      return result.toStringAsExponential(6);
    }
    
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      // Limit decimal places to avoid floating point display issues
      String str = result.toStringAsFixed(10);
      // Remove trailing zeros
      str = str.replaceAll(RegExp(r'0+$'), '');
      str = str.replaceAll(RegExp(r'\.$'), '');
      return str;
    }
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
