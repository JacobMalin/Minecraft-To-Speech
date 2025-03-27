part of 'settings_box.dart';

/// A model for the application settings.
class SettingsModel extends ChangeNotifier {
  /// A model for the application settings.
  SettingsModel() {
    SettingsBox.watchKey('themeMode').listen((_) => notifyListeners());
  }

  var _isSettings = false;

  /// The current tab index.
  var tabIndex = 0;

  /// Whether the current page is the settings page.
  bool get isSettings => _isSettings;
  set isSettings(bool value) {
    _isSettings = value;
    notifyListeners();
  }

  /// The theme brightness mode.
  ThemeMode get themeMode => SettingsBox._themeMode;
  set themeMode(ThemeMode mode) {
    SettingsBox._themeMode = mode;
    notifyListeners();
  }

  /// Hide update messages.
  bool get hideUpdate => SettingsBox._hideUpdate;
  set hideUpdate(bool value) {
    SettingsBox._hideUpdate = value;
    notifyListeners();
  }

  /// Automatically update.
  bool get autoUpdate => SettingsBox.autoUpdate;
  set autoUpdate(bool value) {
    SettingsBox._autoUpdate = value;
    notifyListeners();
  }
}
