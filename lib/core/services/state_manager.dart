import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/i_state_manager.dart';


/// Abstract storage interface for testing
abstract class IStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
  Set<String> getKeys();
}

/// Production storage implementation
class SharedPreferencesStorage implements IStorage {
  SharedPreferences? _prefs;
  
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  @override
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs!.setString(key, value);
  }

  @override
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  @override
  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs!.remove(key);
  }
  
  @override
  Set<String> getKeys() {
    return _prefs?.getKeys() ?? <String>{};
  }
}

/// Mock storage for testing
class MockStorage implements IStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
  
  @override
  Set<String> getKeys() => _data.keys.toSet();
}

/// Implementation of state manager for application state persistence
class StateManager implements IStateManager {
  static const String _pluginStatePrefix = 'plugin_state_';
  static const String _appStatePrefix = 'app_state_';
  
  final StreamController<StateChangeEvent> _stateController = StreamController<StateChangeEvent>.broadcast();
  late final IStorage _storage;
  
  StateManager({IStorage? storage}) {
    _storage = storage ?? SharedPreferencesStorage();
  }
  
  /// Initialize the state manager
  @override
  Future<void> initialize() async {
    // Storage initialization is handled in the constructor
  }
  
  @override
  Future<void> saveState(String key, dynamic value) async {
    final prefKey = '$_appStatePrefix$key';
    final oldValue = await loadState(key);
    
    if (value == null) {
      await _storage.remove(prefKey);
    } else {
      final jsonValue = jsonEncode(value);
      await _storage.setString(prefKey, jsonValue);
    }
    
    _stateController.add(StateChangeEvent(
      key: key,
      oldValue: oldValue,
      newValue: value,
      timestamp: DateTime.now(),
    ));
  }
  
  @override
  Future<T?> loadState<T>(String key) async {
    final prefKey = '$_appStatePrefix$key';
    final jsonValue = await _storage.getString(prefKey);
    
    if (jsonValue == null) {
      return null;
    }
    
    try {
      final decoded = jsonDecode(jsonValue);
      return decoded as T?;
    } catch (e) {
      // If decoding fails, return null and remove invalid data
      await _storage.remove(prefKey);
      return null;
    }
  }
  
  @override
  Future<void> clearState() async {
    final keys = _storage.getKeys().where((key) => key.startsWith(_appStatePrefix));
    
    for (final key in keys) {
      await _storage.remove(key);
    }
    
    _stateController.add(StateChangeEvent(
      key: 'all',
      oldValue: 'existing_state',
      newValue: null,
      timestamp: DateTime.now(),
    ));
  }
  
  @override
  Future<void> syncState() async {
    // In local mode, this is a no-op
    // In online mode, this would sync with cloud storage
    // Implementation depends on current operation mode
  }
  
  @override
  Future<void> savePluginState(String pluginId, Map<String, dynamic> state) async {
    final prefKey = '$_pluginStatePrefix$pluginId';
    final oldState = await loadPluginState(pluginId);
    
    final jsonValue = jsonEncode(state);
    await _storage.setString(prefKey, jsonValue);
    
    _stateController.add(StateChangeEvent(
      key: 'plugin_$pluginId',
      oldValue: oldState,
      newValue: state,
      timestamp: DateTime.now(),
    ));
  }
  
  @override
  Future<Map<String, dynamic>?> loadPluginState(String pluginId) async {
    final prefKey = '$_pluginStatePrefix$pluginId';
    final jsonValue = await _storage.getString(prefKey);
    
    if (jsonValue == null) {
      return null;
    }
    
    try {
      final decoded = jsonDecode(jsonValue);
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      // If decoding fails, return null and remove invalid data
      await _storage.remove(prefKey);
      return null;
    }
  }
  
  @override
  Future<void> clearPluginState(String pluginId) async {
    final prefKey = '$_pluginStatePrefix$pluginId';
    final oldState = await loadPluginState(pluginId);
    
    await _storage.remove(prefKey);
    
    _stateController.add(StateChangeEvent(
      key: 'plugin_$pluginId',
      oldValue: oldState,
      newValue: null,
      timestamp: DateTime.now(),
    ));
  }
  
  @override
  Future<Map<String, Map<String, dynamic>>> getAllPluginStates() async {
    final result = <String, Map<String, dynamic>>{};
    
    final keys = _storage.getKeys().where((key) => key.startsWith(_pluginStatePrefix));
    
    for (final key in keys) {
      final pluginId = key.substring(_pluginStatePrefix.length);
      final state = await loadPluginState(pluginId);
      if (state != null) {
        result[pluginId] = state;
      }
    }
    
    return result;
  }
  
  @override
  Stream<StateChangeEvent> get stateChanges => _stateController.stream;
  
  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}