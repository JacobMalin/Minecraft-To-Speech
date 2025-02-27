import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../setup/hive_setup.dart';

/// A model for the application settings.
class SettingsModel extends ChangeNotifier {
  /// A model for the application settings.
  SettingsModel() {
    _settingsBox.watchKey('themeMode').listen((_) {
      notifyListeners();
    });
  }

  /// Whether the current page is the settings page.
  var isSettings = false;

  /// The discord bot key.
  String? get botKey => _settingsBox['botKey'];
  set botKey(String? key) {
    _settingsBox['botKey'] = key;
    notifyListeners();
  }

  /// The theme brightness mode.
  ThemeMode get themeMode => _settingsBox['themeMode'] == null
      ? ThemeMode.system
      : ThemeMode.values[_settingsBox['themeMode']];
  set themeMode(ThemeMode mode) {
    _settingsBox['themeMode'] = mode.index;
    notifyListeners();
  }

  final Box _settingsBox = HiveSetup.settingsBox();

  /// Changes to or from the settings page.
  void changePage({required bool isSettings}) {
    this.isSettings = isSettings;
    notifyListeners();
  }
}
