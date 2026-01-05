import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:plugin_sdk/sdk.dart';
import 'calculator_ui.dart';
import 'calculator_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize the Plugin SDK
    // await PluginSDK.initialize(
    //   pluginId: 'com.example.calculator',
    //   config: {
    //     'name': 'Calculator Plugin',
    //     'version': '1.0.0',
    //     'type': 'tool',
    //   },
    // );
    
    // Set up lifecycle handlers
    // PluginLifecycleHelper.registerLifecycleHandlers(
    //   onStart: () async {
    //     print('Calculator plugin started');
    //   },
    //   onStop: () async {
    //     print('Calculator plugin stopped');
    //   },
    // );
    
    // Set up event handlers
    // PluginSDK.onHostEvent('theme_changed', _handleThemeChange);
    // PluginSDK.onHostEvent('settings_updated', _handleSettingsUpdate);
    
    runApp(CalculatorApp());
    
    // Report plugin ready
    // await PluginLifecycleHelper.reportReady();
    
  } catch (e) {
    print('Failed to initialize calculator plugin: $e');
    // await PluginLifecycleHelper.reportError(
    //   'Initialization failed',
    //   {'error': e.toString()},
    // );
  }
}

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator Plugin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
      ),
      home: CalculatorHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  @override
  _CalculatorHomePageState createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  late CalculatorEngine _engine;
  bool _showHistory = true;
  
  @override
  void initState() {
    super.initState();
    _engine = CalculatorEngine();
    _loadConfiguration();
    _setupKeyboardShortcuts();
  }

  Future<void> _loadConfiguration() async {
    try {
      // Load plugin configuration
      // final config = await PluginSDK.getPluginConfig();
      // setState(() {
      //   _showHistory = config['show_history'] ?? true;
      //   _engine.precision = config['precision'] ?? 2;
      // });
    } catch (e) {
      print('Failed to load configuration: $e');
    }
  }

  void _setupKeyboardShortcuts() {
    // Set up keyboard shortcuts for calculator operations
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.equal) {
        _engine.calculate();
        setState(() {});
      } else if (key == LogicalKeyboardKey.escape) {
        _engine.clear();
        setState(() {});
      } else if (key == LogicalKeyboardKey.backspace) {
        _engine.backspace();
        setState(() {});
      }
      // Add more keyboard shortcuts as needed
    }
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: _showHistory ? 2 : 1,
            child: CalculatorUI(
              engine: _engine,
              onCalculation: _handleCalculation,
            ),
          ),
          if (_showHistory)
            Expanded(
              flex: 1,
              child: _buildHistoryPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _engine.history.length,
              itemBuilder: (context, index) {
                final entry = _engine.history[index];
                return ListTile(
                  title: Text(entry.expression),
                  subtitle: Text('= ${entry.result}'),
                  onTap: () {
                    _engine.setDisplay(entry.result.toString());
                    setState(() {});
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () {
                _engine.clearHistory();
                setState(() {});
              },
              child: Text('Clear History'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCalculation(String expression, double result) async {
    try {
      // Send calculation event to host
      // await PluginSDK.sendEvent('calculation_performed', {
      //   'expression': expression,
      //   'result': result,
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
      
      // Show notification for large results
      if (result.abs() > 1000000) {
        // await PluginSDK.callHostAPI<void>('showNotification', {
        //   'title': 'Calculator Result',
        //   'message': '$expression = $result',
        //   'type': 'info',
        // });
      }
    } catch (e) {
      print('Failed to handle calculation: $e');
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Calculator Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Show History'),
              value: _showHistory,
              onChanged: (value) {
                setState(() {
                  _showHistory = value;
                });
                Navigator.pop(context);
                _saveConfiguration();
              },
            ),
            ListTile(
              title: Text('Precision'),
              subtitle: Text('${_engine.precision} decimal places'),
              trailing: DropdownButton<int>(
                value: _engine.precision,
                items: [0, 1, 2, 3, 4, 5].map((precision) {
                  return DropdownMenuItem(
                    value: precision,
                    child: Text('$precision'),
                  );
                }).toList(),
                onChanged: (precision) {
                  if (precision != null) {
                    setState(() {
                      _engine.precision = precision;
                    });
                    Navigator.pop(context);
                    _saveConfiguration();
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    try {
      // Save plugin configuration
      // await PluginConfigHelper.setConfig('show_history', _showHistory);
      // await PluginConfigHelper.setConfig('precision', _engine.precision);
    } catch (e) {
      print('Failed to save configuration: $e');
    }
  }
}

// Event handlers for host communication
Future<void> _handleThemeChange(/* HostEvent event */) async {
  // Handle theme changes from host
  print('Theme changed');
}

Future<void> _handleSettingsUpdate(/* HostEvent event */) async {
  // Handle settings updates from host
  print('Settings updated');
}