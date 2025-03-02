import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../setup/hive_setup.dart';

/// A model for the application settings.
class SettingsModel extends ChangeNotifier {
  /// A model for the application settings.
  SettingsModel() {
    SettingsBox.watchKey('themeMode').listen((_) {
      notifyListeners();
    });
  }

  var _isSettings = false;

  /// Whether the current page is the settings page.
  bool get isSettings => _isSettings;
  set isSettings(bool value) {
    _isSettings = value;
    notifyListeners();
  }

  /// The discord bot key.
  String? get botKey => SettingsBox._botKey;
  set botKey(String? key) {
    SettingsBox._botKey = key;
    notifyListeners();
  }

  /// The theme brightness mode.
  ThemeMode get themeMode => SettingsBox._themeMode;
  set themeMode(ThemeMode mode) {
    SettingsBox._themeMode = mode;
    notifyListeners();
  }
}

/// A box for persistent application settings.
class SettingsBox {
  static final Box _settingsBox = Hive.box(name: 'settings');

  /// The discord bot key.
  static String? get _botKey => _settingsBox['botKey'];
  static set _botKey(String? value) {
    _settingsBox['botKey'] = value;
  }

  /// The theme brightness mode.
  static ThemeMode get _themeMode {
    final int? index = _settingsBox['themeMode'];
    return index == null ? ThemeMode.system : ThemeMode.values[index];
  }

  static set _themeMode(ThemeMode mode) {
    _settingsBox['themeMode'] = mode.index;
  }

  /// Whether the window is maximized.
  static bool? get isMaximized => _settingsBox['isMaximized'];
  static set isMaximized(bool? value) {
    _settingsBox['isMaximized'] = value;
  }

  /// The size of the window.
  static Size? get size => _settingsBox['size'];
  static set size(Size? value) {
    _settingsBox['size'] = value != null ? HiveSize.fromSize(value) : null;
  }

  /// The position of the window.
  static Offset? get position => _settingsBox['position'];
  static set position(Offset? value) {
    _settingsBox['position'] =
        value != null ? HiveOffset.fromOffset(value) : null;
  }

  // TODO: Move to instance box
  //// The selected instance index.
  static int? get selectedIndex => _settingsBox['selectedIndex'];
  static set selectedIndex(int? value) {
    _settingsBox['selectedIndex'] = value;
  }

  // TODO: Move to instance box
  //// The list of instance paths.
  static List<String> get paths => [..._settingsBox['paths'] ?? []];
  static set paths(List<String> value) {
    _settingsBox['paths'] = value;
  }

  /// Expose the box watchKey method.
  static Stream watchKey(String key) {
    return _settingsBox.watchKey(key);
  }
}
