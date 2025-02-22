import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:minecraft_to_speech/file/file_filter.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

class FileManager {
  final String path;
  final List<String> messages = [];

  final _filesBox = Hive.box(name: 'files');
  late final Stream<String> _uiStream, _ttsStream, _discordStream;
  StreamSubscription<String>? _uiSubscription,
      _ttsSubscription,
      _discordSubscription;
  final Function _notifyListeners;

  get info => _filesBox[path];
  get name => _filesBox[path].name;
  get isEnabled => _filesBox[path].isEnabled;
  get isTts => _filesBox[path].isTts;
  get isDiscord => _filesBox[path].isDiscord;

  FileManager(this.path, this._notifyListeners) {
    if (!_filesBox.containsKey(path)) _filesBox[path] = FileInfo.fromPath(path);

    final Stream<String> stream = fileStream(path)
        .where(FileFilter.onlyChat)
        .map(FileFilter.commonMap)
        .asBroadcastStream();
    _uiStream = stream.map(FileFilter.uiMap);
    _ttsStream = stream.map(FileFilter.ttsMap);
    _discordStream = stream.map(FileFilter.discordMap);

    updateSubscriptions();
  }

  static updateSubscrption(
      Stream<String> stream,
      StreamSubscription<String>? subscription,
      bool condition,
      void Function(String)? onData) {
    if (condition) return subscription ?? stream.listen(onData);

    subscription?.cancel();
    return null;
  }

  updateSubscriptions() {
    _uiSubscription =
        updateSubscrption(_uiStream, _uiSubscription, isEnabled, (line) {
      messages.insert(0, line);
      _notifyListeners();
    });

    _ttsSubscription = updateSubscrption(
        _ttsStream, _ttsSubscription, isEnabled && isTts, (line) {
      print("tts: $line");
    });

    _discordSubscription = updateSubscrption(
        _discordStream, _discordSubscription, isEnabled && isDiscord, (line) {
      print("discord: $line");
    });
  }

  cleanBox() => _filesBox.delete(path);

  updateWith({String? name, bool? enabled, bool? tts, bool? discord}) {
    var file = _filesBox[path];

    if (name != null) file.name = name;
    if (enabled != null) file.isEnabled = enabled;
    if (tts != null) file.isTts = tts;
    if (discord != null) file.isDiscord = discord;

    _filesBox[path] = file;

    updateSubscriptions();
  }

  openSecondFolder() {
    final secondPath = p.dirname(p.dirname(path));
    OpenFile.open(secondPath);
  }

  static Stream<String> fileStream(String path) async* {
    File file = File(path);

    if (!await file.exists()) return;

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
