import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

class FileManager {
  final _filesBox = Hive.box(name: 'files');
  final String path;

  get info => _filesBox[path];
  get name => _filesBox[path].name;
  get isEnabled => _filesBox[path].isEnabled;
  get isTts => _filesBox[path].isTts;
  get isDiscord => _filesBox[path].isDiscord;

  FileManager(this.path) {
    if (!_filesBox.containsKey(path)) _filesBox[path] = FileInfo.fromPath(path);
    fileStream(path).listen((line) {
      if (isEnabled && isTts) print(line);
    });
  }

  updateStream() {
    // TODO update stream
  }

  cleanBox() => _filesBox.delete(path);

  updateWith({String? name, bool? enabled, bool? tts, bool? discord}) {
    var file = _filesBox[path];

    if (name != null) file.name = name;
    if (enabled != null) file.isEnabled = enabled;
    if (tts != null) file.isTts = tts;
    if (discord != null) file.isDiscord = discord;

    _filesBox[path] = file;
    updateStream();
  }

  openSecondFolder() {
    final secondPath = p.dirname(p.dirname(path));
    OpenFile.open(secondPath);
  }

  static Stream<String> fileStream(String path) async* {
    File file = File(path);
    Directory directory = Directory(p.dirname(path));

    if (!await file.exists()) return;

    int position = await file.length();

    await for (final event in directory.watch()) {
      if (event is FileSystemModifyEvent) {
        int fileLength = await file.length();
        if (fileLength < position) position = 0;

        final stream = file.openRead(position);
        var lines = utf8.decoder.bind(stream).transform(const LineSplitter());
        await for (final line in lines) {
          if (line.isNotEmpty) yield line;
        }

        position = fileLength;
      }
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
