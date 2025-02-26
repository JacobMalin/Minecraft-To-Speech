import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:minecraft_to_speech/file/file_filter.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

class FileManager {
  String path;
  final List<String> messages = [];

  final _filesBox = Hive.box(name: 'files');
  late FileStreamManager _uiStream, _ttsStream, _discordStream;
  final Function _notifyListeners;

  get info => _filesBox[path];
  get name => _filesBox[path].name;
  get isEnabled => _filesBox[path].isEnabled;
  get isTts => _filesBox[path].isTts;
  get isDiscord => _filesBox[path].isDiscord;

  get isValid => File(path).existsSync();
  get isNotValid => !isValid;

  FileManager(this.path, this._notifyListeners) {
    _uiStream = FileStreamManager(
      path,
      notifyListeners: _notifyListeners,
      map: FileFilter.uiMap,
      onData: (line) {
        messages.insert(0, line);
        _notifyListeners();
      },
    );
    _ttsStream = FileStreamManager(
      path,
      notifyListeners: _notifyListeners,
      map: FileFilter.ttsMap,
      onData: (line) {
        // TODO: Finish tts implementation
        if (kDebugMode) print("tts: $line");
      },
    );
    _discordStream = FileStreamManager(
      path,
      notifyListeners: _notifyListeners,
      map: FileFilter.discordMap,
      onData: (line) {
        // TODO: Finish discord implementation
        if (kDebugMode) print("discord: $line");
      },
    );

    if (!_filesBox.containsKey(path)) _filesBox[path] = FileInfo.fromPath(path);

    _uiStream.enabled = isEnabled;
    _ttsStream.enabled = isEnabled && isTts;
    _discordStream.enabled = isEnabled && isDiscord;
  }

  cleanBox() => _filesBox.delete(path);

  updateWith({
    String? name,
    String? path,
    bool? enabled,
    bool? tts,
    bool? discord,
  }) {
    var file = _filesBox[this.path];

    if (path != null) {
      _filesBox.delete(this.path);
      this.path = path;

      _uiStream.path = path;
      _ttsStream.path = path;
      _discordStream.path = path;
    }

    if (name != null) file.name = name;
    if (enabled != null) file.isEnabled = enabled;
    if (tts != null) file.isTts = tts;
    if (discord != null) file.isDiscord = discord;

    _filesBox[this.path] = file;

    _uiStream.enabled = isEnabled;
    _ttsStream.enabled = isEnabled && isTts;
    _discordStream.enabled = isEnabled && isDiscord;
  }

  openSecondFolder() {
    if (isNotValid) return;

    final secondPath = p.dirname(p.dirname(path));
    OpenFile.open(secondPath);
  }
}

class FileInfo {
  String name;
  bool isEnabled, isTts, isDiscord;

  FileInfo.fromPath(path, {name, enabled, tts, discord})
      : name = name ?? secondFolder(path) ?? path,
        isEnabled = enabled ?? true,
        isTts = tts ?? true,
        isDiscord = discord ?? false;

  FileInfo.fromName(this.name, {enabled, tts, discord})
      : isEnabled = enabled ?? true,
        isTts = tts ?? true,
        isDiscord = discord ?? false;

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo.fromName(
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

  static secondFolder(path) {
    List<String> parts = p.split(path);

    return parts.length > 3 ? parts[parts.length - 3] : null;
  }
}

class FileStreamManager {
  final String Function(String) _streamMap;
  final Function(String)? _onData;

  set path(String value) {
    _initializeStream(value);
  }

  bool _enabled = false;
  set enabled(bool value) {
    if (value == _enabled) return;

    _enabled = value;

    _unsubscribe();
    if (_enabled) _subscribe();
  }

  Stream<String>? _stream;
  StreamSubscription<String>? _subscription;
  StreamSubscription<FileSystemEvent>? _fileWatch;

  final Function _notifyListeners;

  FileStreamManager(path,
      {required notifyListeners, required map, required onData})
      : _notifyListeners = notifyListeners,
        _streamMap = map,
        _onData = onData {
    _initializeStream(path);
  }

  void _initializeStream(String path) {
    _fileWatch?.cancel();
    _fileWatch = Directory(p.dirname(path))
        .watch(events: FileSystemEvent.all)
        .listen((event) {
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

    _unsubscribe();
    if (_enabled) _subscribe();
  }

  void _makeStream(String path) {
    _stream = _fileStream(path)
        .where(FileFilter.onlyChat)
        .map(FileFilter.commonMap)
        .map(_streamMap)
        .asBroadcastStream();
  }

  void _subscribe() {
    _subscription = _stream?.listen(_onData);
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Stream<String> _fileStream(String path) async* {
    File file = File(path);

    int position = await file.length();

    await for (final _ in Stream.periodic(Duration(milliseconds: 100))) {
      int fileLength = await file.length();
      if (fileLength < position) position = 0;

      final stream = file.openRead(position);
      final lines = utf8.decoder.bind(stream).transform(const LineSplitter());
      await for (final line in lines) {
        if (line.isNotEmpty) yield line;
      }

      position = fileLength;
    }
  }
}
