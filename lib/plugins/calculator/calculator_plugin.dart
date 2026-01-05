import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';

/// A simple calculator plugin that demonstrates tool plugin implementation
class CalculatorPlugin implements IPlugin {
  late PluginContext _context;
  String _display = '0';
  String _previousValue = '';
  String _operation = '';
  bool _waitingForOperand = false;

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
      _display = savedState['display'] ?? '0';
      _previousValue = savedState['previousValue'] ?? '';
      _operation = savedState['operation'] ?? '';
      _waitingForOperand = savedState['waitingForOperand'] ?? false;
    }

    // Show notification that calculator is ready
    await _context.platformServices.showNotification('Calculator plugin initialized');
  }

  @override
  Future<void> dispose() async {
    // Save current state before disposal
    await _saveState();
    await _context.platformServices.showNotification('Calculator plugin disposed');
  }

  @override
  Widget buildUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
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
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _display,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                  ),
                ),
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
    
    // Save state after each operation
    _saveState();
  }

  void _clear() {
    _display = '0';
    _previousValue = '';
    _operation = '';
    _waitingForOperand = false;
  }

  void _toggleSign() {
    if (_display != '0') {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    }
  }

  void _percentage() {
    final value = double.tryParse(_display);
    if (value != null) {
      _display = (value / 100).toString();
      _waitingForOperand = true;
    }
  }

  void _setOperation(String operation) {
    if (_previousValue.isNotEmpty && !_waitingForOperand) {
      _calculate();
    }
    
    _previousValue = _display;
    _operation = operation;
    _waitingForOperand = true;
  }

  void _calculate() {
    if (_previousValue.isEmpty || _operation.isEmpty) return;
    
    final prev = double.tryParse(_previousValue);
    final current = double.tryParse(_display);
    
    if (prev == null || current == null) return;
    
    double result;
    switch (_operation) {
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
          _display = 'Error';
          return;
        }
        result = prev / current;
        break;
      default:
        return;
    }
    
    _display = _formatResult(result);
    _previousValue = '';
    _operation = '';
    _waitingForOperand = true;
  }

  String _formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toString();
    }
  }

  void _addDigit(String digit) {
    if (_waitingForOperand) {
      _display = digit;
      _waitingForOperand = false;
    } else {
      _display = _display == '0' ? digit : _display + digit;
    }
  }

  void _addDecimal() {
    if (_waitingForOperand) {
      _display = '0.';
      _waitingForOperand = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
  }

  Future<void> _saveState() async {
    final state = {
      'display': _display,
      'previousValue': _previousValue,
      'operation': _operation,
      'waitingForOperand': _waitingForOperand,
    };
    await _context.dataStorage.store('calculator_state', state);
  }

  @override
  Future<void> onStateChanged(PluginState state) async {
    switch (state) {
      case PluginState.active:
        // Plugin became active, no special action needed
        break;
      case PluginState.paused:
        // Save state when paused
        await _saveState();
        break;
      case PluginState.inactive:
        // Plugin becoming inactive, save state
        await _saveState();
        break;
      case PluginState.error:
        // Handle error state
        _clear();
        break;
      case PluginState.loading:
        // Plugin is loading, no action needed
        break;
    }
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    return {
      'display': _display,
      'previousValue': _previousValue,
      'operation': _operation,
      'waitingForOperand': _waitingForOperand,
    };
  }
}