import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../setup/hive_setup.dart';
import 'log_filter.dart';

/// Manages a minecraft instance. This includes the log streams and instance
/// info.
class InstanceController {
  /// Creates a controller for a minecraft instance.
  InstanceController(this.path, this._notifyListeners) {
    _uiStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      map: LogFilter.uiMap,
      onData: (line) {
        messages.insert(0, line);
        _notifyListeners();
      },
    );

    _ttsStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      map: LogFilter.ttsMap,
      onData: (line) {
        // TODO: Finish tts implementation
        if (kDebugMode) print('tts: $line');
      },
    );

    _discordStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      map: LogFilter.discordMap,
      onData: (line) {
        // TODO: Finish discord implementation
        if (kDebugMode) print('discord: $line');
      },
    );

    if (!_instancesBox.containsKey(path)) {
      _instancesBox[path] = InstanceInfo.fromPath(path);
    }

    _uiStream.enabled = isEnabled;
    _ttsStream.enabled = isEnabled && isTts;
    _discordStream.enabled = isEnabled && isDiscord;
  }

  /// The path to the "latest.log" file of the instance.
  String path;

  /// The chat messages that have been received during this session. This is
  /// empty on boot.
  final List<String> messages = [];

  final Box _instancesBox = HiveSetup.instancesBox();
  late LogStreamController _uiStream, _ttsStream, _discordStream;
  final VoidCallback _notifyListeners;

  /// The persitent data of the instance.
  InstanceInfo get info => _instancesBox[path];

  /// The user-defined name of the instance.
  String get name => info.name;

  /// Whether the instance is enabled. Disabled instances will not consume chat
  /// messages
  bool get isEnabled => info.isEnabled;

  /// Whether the instance should use text-to-speech. Text-to-speech is also
  /// disabled when isEnabled is false.
  bool get isTts => info.isTts;

  /// Whether the instance should use send chat messages to Discord. Discord is
  /// also disabled when isEnabled is false.
  bool get isDiscord => info.isDiscord;

  /// Whether the log file for the instance exists.
  bool get isValid => File(path).existsSync();

  /// Whether the log file for the instance does not exist.
  bool get isNotValid => !isValid;

  /// Delete all stored persistent data.
  void cleanBox() => _instancesBox.delete(path);

  /// Update the instance with new data. This will update the persistent data
  /// and the streams.
  void updateWith({
    String? name,
    String? path,
    bool? enabled,
    bool? tts,
    bool? discord,
  }) {
    final InstanceInfo instance = _instancesBox[this.path];

    if (path != null) {
      _instancesBox.delete(this.path);
      this.path = path;

      _uiStream.path = path;
      _ttsStream.path = path;
      _discordStream.path = path;
    }

    if (name != null) instance.name = name;
    if (enabled != null) instance.isEnabled = enabled;
    if (tts != null) instance.isTts = tts;
    if (discord != null) instance.isDiscord = discord;

    _instancesBox[this.path] = instance;

    _uiStream.enabled = isEnabled;
    _ttsStream.enabled = isEnabled && isTts;
    _discordStream.enabled = isEnabled && isDiscord;
  }

  /// Open the instance folder, which is one level above the log folder.
  Future<void> openInstanceFolder() async {
    if (isNotValid) return;

    final String secondDirectory = p.dirname(p.dirname(path));
    await OpenFile.open(secondDirectory);
  }
}

/// The persistent data of a minecraft instance.
class InstanceInfo {
  /// Creates an instance info from a path to "latest.log".
  InstanceInfo.fromPath(String path, {name, enabled, tts, discord})
      : name = name ?? instanceDirectoryName(path) ?? path,
        isEnabled = enabled ?? true,
        isTts = tts ?? true,
        isDiscord = discord ?? false;

  InstanceInfo._fromName(this.name, {enabled, tts, discord})
      : isEnabled = enabled ?? true,
        isTts = tts ?? true,
        isDiscord = discord ?? false;

  /// Creates an instance info from a json object. This is used to recall
  /// persistent data.
  factory InstanceInfo.fromJson(Map<String, dynamic> json) =>
      InstanceInfo._fromName(
        json['name'] as String,
        enabled: json['isEnabled'] is bool ? json['isEnabled'] as bool : null,
        tts: json['isTts'] is bool ? json['isTts'] as bool : null,
        discord: json['isDiscord'] is bool ? json['isDiscord'] as bool : null,
      );

  /// The user-defined name of the instance.
  String name;

  /// Whether the instance is enabled. Disabled instances will not consume chat.
  bool isEnabled;

  /// Whether the instance should use text-to-speech.
  bool isTts;

  /// Whether the instance should use send chat messages to Discord.
  bool isDiscord;

  /// Converts the instance info to a json object. This is used to store
  /// persistent data.
  Map<String, dynamic> toJson() => {
        'name': name,
        'isEnabled': isEnabled,
        'isTts': isTts,
        'isDiscord': isDiscord,
      };

  /// Gets the name of the instance directory from the path to "latest.log".
  static String? instanceDirectoryName(String path) {
    final List<String> parts = p.split(path);

    return parts.length > 3 ? parts[parts.length - 3] : null;
  }
}

/// Manages a stream of log messages from "latest.log". This is used to manage
/// the chat, text-to-speech, and Discord streams.
class LogStreamController {
  /// Creates a controller for a log stream.
  LogStreamController(
    String path, {
    required VoidCallback notifyListeners,
    required String Function(String) map,
    required void Function(String)? onData,
  })  : _notifyListeners = notifyListeners,
        _streamMap = map,
        _onData = onData {
    unawaited(_initializeStream(path));
  }

  final String Function(String) _streamMap;
  final Function(String)? _onData;

  set path(String value) {
    unawaited(_initializeStream(value));
  }

  var _enabled = false;
  set enabled(bool value) {
    if (value == _enabled) return;

    _enabled = value;

    unawaited(
      _unsubscribe().then((_) {
        if (_enabled) _subscribe();
      }),
    );
  }

  Stream<String>? _stream;
  StreamSubscription<String>? _subscription;
  StreamSubscription<FileSystemEvent>? _logWatch;

  final VoidCallback _notifyListeners;

  Future<void> _initializeStream(String path) async {
    unawaited(_logWatch?.cancel());
    _logWatch = Directory(p.dirname(path)).watch().listen((event) {
      if (event.path == path) {
        if (event is FileSystemDeleteEvent) {
          _stream = null;
          _unsubscribe();

          _notifyListeners();
        } else if (event is FileSystemCreateEvent) {
          _makeStream(path);
          if (_enabled) _subscribe();

          _notifyListeners();
        }
      }
    });

    _stream = null;
    if (File(path).existsSync()) {
      _makeStream(path);
    }

    await _unsubscribe();
    if (_enabled) _subscribe();
  }

  void _makeStream(String path) {
    _stream = _logStream(path)
        .where(LogFilter.onlyChat)
        .map(LogFilter.commonMap)
        .map(_streamMap)
        .asBroadcastStream();
  }

  void _subscribe() {
    _subscription = _stream?.listen(_onData);
  }

  Future<void> _unsubscribe() async {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  static Stream<String> _logStream(String path) async* {
    final log = File(path);

    int position = await log.length();

    await for (final void _ in Stream.periodic(
      const Duration(milliseconds: 100),
    )) {
      final int fileLength = await log.length();
      if (fileLength < position) position = 0;

      final Stream<List<int>> stream = log.openRead(position);
      final Stream<String> lines =
          utf8.decoder.bind(stream).transform(const LineSplitter());
      await for (final line in lines) {
        if (line.isNotEmpty) yield line;
      }

      position = fileLength;
    }
  }
}
