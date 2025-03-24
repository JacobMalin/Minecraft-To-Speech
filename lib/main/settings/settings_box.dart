import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:velopack_flutter/velopack_flutter.dart' as velopack;
import '../../setup/hive_setup.dart';

part 'settings_model.dart';
part 'velopack_model.dart';

/// A box for persistent application settings.
class SettingsBox {
  static final Box _settingsBox = Hive.box(name: 'settings');

  /// The discord bot key.
  static String? get botKey => _settingsBox['botKey'];
  static set botKey(String? value) {
    _settingsBox['botKey'] = value;
  }

  /// The discord bot channel id.
  static int? get botChannel => _settingsBox['botChannel'];
  static set botChannel(int? value) {
    _settingsBox['botChannel'] = value;
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

  /// The github rate limit reset time. Stored as miliseconds since epoch.
  static DateTime? get limitUntil {
    if (!_settingsBox.containsKey('limitUntil')) return null;
    return DateTime.fromMillisecondsSinceEpoch(_settingsBox['limitUntil']);
  }

  static set limitUntil(DateTime? value) {
    _settingsBox['limitUntil'] = value?.millisecondsSinceEpoch;
  }

  /// The last time the version was checked
  static DateTime? get _lastChecked {
    if (!_settingsBox.containsKey('lastChecked')) return null;
    return DateTime.fromMillisecondsSinceEpoch(_settingsBox['lastChecked']);
  }

  static set _lastChecked(DateTime? value) {
    _settingsBox['lastChecked'] = value?.millisecondsSinceEpoch;
  }

  /// The latest version of the software
  static String? get _latestVersion => _settingsBox['latestVersion'];
  static set _latestVersion(String? value) {
    _settingsBox['latestVersion'] = value;
  }

  /// The last known path to the MultiMC launcher.
  static String? get multiMCPath => _settingsBox['multiMCPath'];
  static set multiMCPath(String? value) {
    _settingsBox['multiMCPath'] = value;
  }

  /// Expose the box watchKey method.
  static Stream watchKey(String key) {
    return _settingsBox.watchKey(key);
  }
}
