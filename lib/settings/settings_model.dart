import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsModel extends ChangeNotifier {
  bool isSettings = false;
  final settingsBox = Hive.box(name: 'settings');

  void changePage(isSettings) {
    this.isSettings = isSettings;
    notifyListeners();
  }

  String? get botKey => settingsBox['botKey'];

  set botKey(String? key) {
    settingsBox['botKey'] = key;
    notifyListeners();
  }

  ThemeMode get themeMode => settingsBox['themeMode'] == null
      ? ThemeMode.system
      : ThemeMode.values[settingsBox['themeMode']];

  set themeMode(ThemeMode mode) {
    settingsBox['themeMode'] = mode.index;
    notifyListeners();
  }
}
