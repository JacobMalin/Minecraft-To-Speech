import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import 'instance_model.dart';
import 'log_filter.dart';

/// Manages a minecraft instance. This includes the log streams and instance
/// info.
class InstanceController {
  /// Creates a controller for a minecraft instance.
  InstanceController(this.path, this._notifyListeners) {
    // Add path info to box if it doesn't exist
    if (!InstanceBox.infos.containsKey(path)) {
      InstanceBox.infos[path] = InstanceInfo.fromPath(path);
    }

    // TODO: Add log river
    // TODO: Intercept the river at the source and move chat commands there
    _commandStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      where: LogFilter.onlyFailedCommands,
      map: LogFilter.commandMap,
      onData: (line) {
        final List<String> args = line.split(' ');

        if (args[0] != 'mts') return;

        if (kDebugMode) print('Command!');
      },
    );
    _commandStream.enable(isEnabled);

    _uiStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      map: LogFilter.uiMap,
      onData: (line) {
        messages.insert(0, line);
        _notifyListeners();
      },
    );
    _uiStream.enable(isEnabled);

    // TODO: Queue tts messages
    unawaited(
      _configureTts().then((_) {
        _ttsStream = LogStreamController(
          path,
          notifyListeners: _notifyListeners,
          map: LogFilter.ttsMap,
          onData: (line) async {
            await _flutterTts.speak(line);
          },
          onCancel: () async {
            await _flutterTts.stop();
          },
        );
        _ttsStream.enable(isEnabled && isTts);
      }),
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
    _discordStream.enable(isEnabled && isDiscord);
  }

  /// The path to the "latest.log" file of the instance.
  String path;

  /// The chat messages that have been received during this session. This is
  /// empty on boot.
  final List<String> messages = [];

  late LogStreamController _commandStream,
      _uiStream,
      _ttsStream,
      _discordStream;
  final VoidCallback _notifyListeners;

  /// The persitent data of the instance.
  InstanceInfo get info => InstanceBox.infos[path]!;

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

  /// The directory of the instance. This is two levels above the log file.
  String get instanceDirectory => p.dirname(p.dirname(path));

  final _flutterTts = FlutterTts();

  Future<void> _configureTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(1);
    await _flutterTts.setVolume(1);
  }

  /// Delete all stored persistent data.
  void cleanBox() => InstanceBox.infos.delete(path);

  /// Update the instance with new data. This will update the persistent data
  /// and the streams.
  void updateWith({
    String? name,
    String? path,
    bool? enabled,
    bool? tts,
    bool? discord,
  }) {
    final InstanceInfo info = this.info;

    if (path != null) {
      cleanBox();
      this.path = path;

      _commandStream.path = path;
      _uiStream.path = path;
      _ttsStream.path = path;
      _discordStream.path = path;
    }

    if (name != null) info.name = name;
    if (enabled != null) info.isEnabled = enabled;
    if (tts != null) info.isTts = tts;
    if (discord != null) info.isDiscord = discord;

    InstanceBox.infos[this.path] = info;

    _commandStream.enable(isEnabled);
    _uiStream.enable(isEnabled);
    _ttsStream.enable(isEnabled && isTts);
    _discordStream.enable(isEnabled && isDiscord);
  }

  /// Open the instance folder, which is one level above the log folder.
  Future<void> openInstanceDirectory() async {
    if (isNotValid) return;

    await OpenFile.open(instanceDirectory);
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
    final String instanceDirectory = p.dirname(p.dirname(path));
    final String dirname = p.basename(instanceDirectory);

    if (dirname == '.minecraft') return 'Default';

    return dirname;
  }
}

/// Manages a stream of log messages from "latest.log". This is used to manage
/// the chat, text-to-speech, and Discord streams.
class LogStreamController {
  /// Creates a controller for a log stream.
  LogStreamController(
    String path, {
    required VoidCallback notifyListeners,
    required void Function(String) onData,
    bool Function(String)? where,
    String Function(String)? map,
    void Function()? onCancel,
  })  : _notifyListeners = notifyListeners,
        _streamWhere = where ?? ((_) => true),
        _streamMap = map ?? ((line) => line),
        _onData = onData,
        _onCancel = onCancel {
    unawaited(_initializeStream(path));
  }

  final VoidCallback _notifyListeners;
  final bool Function(String) _streamWhere;
  final String Function(String) _streamMap;
  final Function(String) _onData;
  final Function()? _onCancel;

  set path(String value) {
    unawaited(_initializeStream(value));

    unawaited(
      _unsubscribe().then((_) {
        if (_enabled) _subscribe();
      }),
    );
  }

  var _enabled = false;

  /// Starts or stops the stream.
  // ignore: avoid_positional_boolean_parameters
  void enable(bool value) {
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

  Future<void> _initializeStream(String path) async {
    unawaited(_logWatch?.cancel());
    _logWatch = Directory(p.dirname(path)).watch().listen((event) async {
      if (event.path == path) {
        switch (event.runtimeType) {
          case const (FileSystemDeleteEvent):
          case const (FileSystemMoveEvent):
            _stream = null;
            await _unsubscribe();

            _notifyListeners();
          case const (FileSystemCreateEvent):
            _makeStream(path);
            await _unsubscribe();
            if (_enabled) _subscribe();

            _notifyListeners();
        }
      } else if (event is FileSystemMoveEvent && event.destination == path) {
        _makeStream(path);
        await _unsubscribe();
        if (_enabled) _subscribe();

        _notifyListeners();
      }
    });

    _stream = null;
    if (File(path).existsSync()) {
      _makeStream(path);
    }
  }

  void _makeStream(String path) {
    _stream = _logStream(path)
        .where(LogFilter.onlyChat)
        .map(LogFilter.commonMap)
        .where(_streamWhere)
        .map(_streamMap)
        .asBroadcastStream();
  }

  void _subscribe() {
    _subscription = _stream?.listen(
      _onData,
      onError: (error) async {
        if (error is PathNotFoundException) {
          _stream = null;
          await _unsubscribe();
        } else if (kDebugMode) {
          print('Error in log stream: $error');
        }
      },
    );
  }

  Future<void> _unsubscribe() async {
    unawaited(_subscription?.cancel());
    _subscription = null;

    _onCancel?.call();
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
