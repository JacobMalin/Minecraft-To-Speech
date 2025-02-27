import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../setup/hive_setup.dart';
import 'log_filter.dart';

class InstanceController {
  String path;
  final List<String> messages = [];

  final Box _instancesBox = HiveSetup.instancesBox();
  late LogStreamController _uiStream, _ttsStream, _discordStream;
  final Function _notifyListeners;

  InstanceInfo get info => _instancesBox[path];
  String get name => _instancesBox[path].name;
  bool get isEnabled => _instancesBox[path].isEnabled;
  bool get isTts => _instancesBox[path].isTts;
  bool get isDiscord => _instancesBox[path].isDiscord;

  bool get isValid => File(path).existsSync();
  bool get isNotValid => !isValid;

  InstanceController(this.path, this._notifyListeners) {
    _uiStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      map: LogFilter.uiMap,
      onData: (final line) {
        messages.insert(0, line);
        _notifyListeners();
      },
    );
    _ttsStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      map: LogFilter.ttsMap,
      onData: (final line) {
        // TODO: Finish tts implementation
        if (kDebugMode) print('tts: $line');
      },
    );
    _discordStream = LogStreamController(
      path,
      notifyListeners: _notifyListeners,
      map: LogFilter.discordMap,
      onData: (final line) {
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

  void cleanBox() => _instancesBox.delete(path);

  void updateWith({
    final String? name,
    final String? path,
    final bool? enabled,
    final bool? tts,
    final bool? discord,
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

  Future<void> openSecondFolder() async {
    if (isNotValid) return;

    final String secondPath = p.dirname(p.dirname(path));
    await OpenFile.open(secondPath);
  }
}

class InstanceInfo {
  String name;
  bool isEnabled, isTts, isDiscord;

  InstanceInfo.fromPath(final path,
      {final name, final enabled, final tts, final discord})
      : name = name ?? secondFolder(path) ?? path,
        isEnabled = enabled ?? true,
        isTts = tts ?? true,
        isDiscord = discord ?? false;

  InstanceInfo.fromName(this.name, {final enabled, final tts, final discord})
      : isEnabled = enabled ?? true,
        isTts = tts ?? true,
        isDiscord = discord ?? false;

  factory InstanceInfo.fromJson(final Map<String, dynamic> json) =>
      InstanceInfo.fromName(
        json['name'] as String,
        enabled: json['isEnabled'] is bool ? json['isEnabled'] as bool : null,
        tts: json['isTts'] is bool ? json['isTts'] as bool : null,
        discord: json['isDiscord'] is bool ? json['isDiscord'] as bool : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'isEnabled': isEnabled,
        'isTts': isTts,
        'isDiscord': isDiscord,
      };

  static String? secondFolder(final path) {
    final List<String> parts = p.split(path);

    return parts.length > 3 ? parts[parts.length - 3] : null;
  }
}

class LogStreamController {
  final String Function(String) _streamMap;
  final Function(String)? _onData;

  set path(final String value) {
    unawaited(_initializeStream(value));
  }

  bool _enabled = false;
  set enabled(final bool value) {
    if (value == _enabled) return;

    _enabled = value;

    unawaited(_unsubscribe().then((final _) {
      if (_enabled) _subscribe();
    }));
  }

  Stream<String>? _stream;
  StreamSubscription<String>? _subscription;
  StreamSubscription<FileSystemEvent>? _logWatch;

  final Function _notifyListeners;

  LogStreamController(final path,
      {required final Function notifyListeners,
      required final String Function(String) map,
      required final void Function(String)? onData})
      : _notifyListeners = notifyListeners,
        _streamMap = map,
        _onData = onData {
    unawaited(_initializeStream(path));
  }

  Future<void> _initializeStream(final String path) async {
    unawaited(_logWatch?.cancel());
    _logWatch = Directory(p.dirname(path)).watch().listen((final event) {
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

  void _makeStream(final String path) {
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

  static Stream<String> _logStream(final String path) async* {
    final File log = File(path);

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
