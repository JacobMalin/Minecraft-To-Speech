part of 'settings_box.dart';

/// Setup velopack installation support
class VelopackModel extends ChangeNotifier {
  /// A model for the velopack installation support.
  VelopackModel() {
    Future<void> init() async {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;

      if (SettingsBox.autoUpdate) {
        if (updateAvailable == UpdateResult.available) {
          await updateAndRestart();
          if (kDebugMode) print('Update and restart');
        }

        WindowSetup.main();
      } else {
        WindowSetup.main();

        // Request the current version
        await checkForUpdates();
      }
    }

    unawaited(init());
  }

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
  }

  static var ready = false;

  var _mutex = false;

  /// The current version of the software.
  late final String currentVersion;

  /// The status of the last update check.
  UpdateResult? updateAvailable;

  static const _orgOrUser = 'JacobMalin';
  static const _repoName = 'Minecraft-To-Speech';

  DateTime? get _limitUntil => SettingsBox.limitUntil;
  set _limitUntil(DateTime? value) {
    SettingsBox.limitUntil = value;
  }

  /// The last time the version was checked.
  DateTime? get lastChecked => SettingsBox._lastChecked;
  set lastChecked(DateTime? value) {
    SettingsBox._lastChecked = value;
    notifyListeners();
  }

  /// The latest version of the software.
  String? get latestVersion => SettingsBox._latestVersion;
  set latestVersion(String? value) {
    SettingsBox._latestVersion = value;
    notifyListeners();
  }

  void _limitFor(Duration duration) {
    _limitUntil = DateTime.now().add(duration);
  }

  Future<void> _requestVersion() async {
    final bool isLimited =
        _limitUntil != null && DateTime.now().isBefore(_limitUntil!);
    final bool isTooSoon =
        lastChecked != null && lastChecked!.isWithinAMinute();
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

        latestVersion = tagName.split('v').last;
        lastChecked = DateTime.now();
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
      'https://github.com/$_orgOrUser/$_repoName/releases/download/v$version/';

  /// Check if an update is available
  Future<UpdateResult> checkForUpdates() async {
    updateAvailable = await _isUpdateAvailable();

    notifyListeners();

    return updateAvailable!;
  }

  Future<UpdateResult> _isUpdateAvailable() async {
    await _requestVersion();

    if (latestVersion == null) return UpdateResult.failed;
    if (lastChecked != null && lastChecked!.isOverAMinuteAgo()) {
      return UpdateResult.outOfDate;
    }

    if (latestVersion == currentVersion) return UpdateResult.notAvailable;

    if (kDebugMode) return UpdateResult.debug;

    if (await velopack.isUpdateAvailable(
      url: _urlFromVersion(latestVersion!),
    )) {
      return UpdateResult.available;
    } else {
      return UpdateResult.notAvailable;
    }
  }

  /// Update and restart the app
  Future<UpdateResult> updateAndRestart() async {
    if (latestVersion == null) return UpdateResult.failed;
    if (kDebugMode) return UpdateResult.debug;

    await velopack.updateAndRestart(url: _urlFromVersion(latestVersion!));
    return UpdateResult.success;
  }

  /// Update and exit the app
  Future<UpdateResult> updateAndExit() async {
    if (latestVersion == null) return UpdateResult.failed;
    if (kDebugMode) return UpdateResult.debug;

    await velopack.updateAndExit(url: _urlFromVersion(latestVersion!));
    return UpdateResult.success;
  }

  /// Wait for the app to exit, then update
  Future<UpdateResult> waitExitThenUpdate({
    required bool silent,
    required bool restart,
  }) async {
    if (latestVersion == null) return UpdateResult.failed;
    if (kDebugMode) return UpdateResult.debug;

    await velopack.waitExitThenUpdate(
      url: _urlFromVersion(latestVersion!),
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
