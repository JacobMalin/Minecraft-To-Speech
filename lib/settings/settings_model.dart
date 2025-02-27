import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../setup/hive_setup.dart';

class SettingsModel extends ChangeNotifier {
  bool isSettings = false;
  final Box settingsBox = HiveSetup.settingsBox();

  SettingsModel() {
    settingsBox.watchKey('themeMode').listen((final _) {
      notifyListeners();
    });
  }

  void changePage({required final bool isSettings}) {
    this.isSettings = isSettings;
    notifyListeners();
  }

  String? get botKey => settingsBox['botKey'];

  set botKey(final String? key) {
    settingsBox['botKey'] = key;
    notifyListeners();
  }

  ThemeMode get themeMode => settingsBox['themeMode'] == null
      ? ThemeMode.system
      : ThemeMode.values[settingsBox['themeMode']];

  set themeMode(final ThemeMode mode) {
    settingsBox['themeMode'] = mode.index;
    notifyListeners();
  }
}
