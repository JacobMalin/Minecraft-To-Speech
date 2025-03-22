part of 'settings_box.dart';

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

  /// The theme brightness mode.
  ThemeMode get themeMode => SettingsBox._themeMode;
  set themeMode(ThemeMode mode) {
    SettingsBox._themeMode = mode;
    notifyListeners();
  }
}
