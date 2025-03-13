import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:velopack_flutter/velopack_flutter.dart' as velopack;

import '../main/settings/settings_model.dart';

/// Setup velopack installation support
class VelopackSetup {
  /// Initialize velopack
  static Future<void> setup(List<String> args) async {
    await velopack.RustLib.init();

    const veloCommands = [
      '--veloapp-install',
      '--veloapp-updated',
      '--veloapp-obsolete',
      '--veloapp-uninstall',
    ];
    if (veloCommands.any((cmd) => args.contains(cmd))) {
      exit(0);
    }

    // Request the current version
    await _requestVersion();

    // TODO: Implement auto-update
  }

  static var _mutex = false;

  static const _orgOrUser = 'JacobMalin';
  static const _repoName = 'Minecraft-To-Speech';

  static DateTime? get _limitUntil => SettingsBox.limitUntil;
  static set _limitUntil(DateTime? value) {
    SettingsBox.limitUntil = value;
  }

  static DateTime? get _lastChecked => SettingsBox.lastChecked;
  static set _lastChecked(DateTime? value) {
    SettingsBox.lastChecked = value;
  }

  static String? get _latestVersion => SettingsBox.latestVersion;
  static set _latestVersion(String? value) {
    SettingsBox.latestVersion = value;
  }

  static void _limitFor(Duration duration) {
    _limitUntil = DateTime.now().add(duration);
  }

  static Future<void> _requestVersion() async {
    final bool isLimited =
        _limitUntil != null && DateTime.now().isBefore(_limitUntil!);
    final bool isTooSoon =
        _lastChecked != null && _lastChecked!.isWithinAMinute();
    if (_mutex || isLimited || isTooSoon) {
      return;
    }
    _mutex = true;

    final url = Uri.https(
      'api.github.com',
      '/repos/$_orgOrUser/$_repoName/releases/latest',
    );

    final http.Response response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> data = json.decode(response.body);
        final String tagName = data['tag_name']!;

        _limitFor(const Duration(minutes: 1));

        _latestVersion = tagName.split('v').last;
        _lastChecked = DateTime.now();
        _mutex = false;
        return;
      case 403:
      case 429:
        if (kDebugMode) print('GitHub: Rate limited');

        if (response.headers.containsKey('x-ratelimit-remaining')) {
          final int remaining =
              int.parse(response.headers['x-ratelimit-remaining']!);
          if (remaining == 0) {
            final int reset = int.parse(response.headers['x-ratelimit-reset']!);
            final resetTime = DateTime.fromMillisecondsSinceEpoch(
              reset * Duration.millisecondsPerSecond,
            );
            final Duration duration = DateTime.now().difference(resetTime);

            _limitFor(duration);
          }
        } else if (response.headers.containsKey('retry-after')) {
          final int seconds = int.parse(response.headers['retry-after']!);
          final duration = Duration(seconds: seconds);

          _limitFor(duration);
        }
    }

    _mutex = false;
    return;
  }

  static String _urlFromVersion(String version) =>
      '$_orgOrUser/$_repoName/releases/download/v$version/';

  /// Check if an update is available
  static Future<UpdateResult> isUpdateAvailable() async {
    await _requestVersion();

    if (_latestVersion == null) return UpdateResult.failed;
    if (_lastChecked != null && _lastChecked!.isOverAMinuteAgo()) {
      return UpdateResult.outOfDate;
    }
    if (kDebugMode) return UpdateResult.debug;

    if (await velopack.isUpdateAvailable(
      url: _urlFromVersion(_latestVersion!),
    )) {
      return UpdateResult.available;
    } else {
      return UpdateResult.notAvailable;
    }
  }

  /// Update and restart the app
  static Future<UpdateResult> updateAndRestart() async {
    await _requestVersion();

    if (_latestVersion == null) return UpdateResult.failed;
    if (_lastChecked != null && _lastChecked!.isOverAMinuteAgo()) {
      return UpdateResult.outOfDate;
    }
    if (kDebugMode) return UpdateResult.debug;

    await velopack.updateAndRestart(url: _urlFromVersion(_latestVersion!));
    return UpdateResult.success;
  }

  /// Update and exit the app
  static Future<UpdateResult> updateAndExit() async {
    await _requestVersion();

    if (_latestVersion == null) return UpdateResult.failed;
    if (_lastChecked != null && _lastChecked!.isOverAMinuteAgo()) {
      return UpdateResult.outOfDate;
    }
    if (kDebugMode) return UpdateResult.debug;

    await velopack.updateAndExit(url: _urlFromVersion(_latestVersion!));
    return UpdateResult.success;
  }

  /// Wait for the app to exit, then update
  static Future<UpdateResult> waitExitThenUpdate({
    required bool silent,
    required bool restart,
  }) async {
    await _requestVersion();

    if (_latestVersion == null) return UpdateResult.failed;
    if (_lastChecked != null && _lastChecked!.isOverAMinuteAgo()) {
      return UpdateResult.outOfDate;
    }
    if (kDebugMode) return UpdateResult.debug;

    await velopack.waitExitThenUpdate(
      url: _urlFromVersion(_latestVersion!),
      silent: silent,
      restart: restart,
    );
    return UpdateResult.success;
  }
}

/// The status of the update check
enum UpdateResult {
  /// An update is available
  available,

  /// An update is not available
  notAvailable,

  /// The update is starting
  success,

  /// The update check failed for unknown reasons
  failed,

  /// The update check likely failed due to no internet connection
  outOfDate,

  /// The update check failed due to being in debug mode
  debug,
}

extension _WeirdDateTimeChecks on DateTime {
  bool isOverAMinuteAgo() =>
      isBefore(DateTime.now().subtract(const Duration(minutes: 1)));
  bool isWithinAMinute() =>
      isAfter(DateTime.now().subtract(const Duration(minutes: 1)));
}
