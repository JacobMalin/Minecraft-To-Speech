import 'dart:io';

import 'package:path/path.dart' as p;

class FileSettings {
  final File file;
  String name;
  bool isEnabled;
  bool isTts;
  bool isDiscord;

  get path => file.path;

  FileSettings.fromPath(path, {name, enabled, tts, discord})
      : file = File(path),
        name = name ?? secondFolder(path) ?? path,
        isEnabled = enabled ?? false,
        isTts = tts ?? false,
        isDiscord = discord ?? false;

  factory FileSettings.fromJson(Map<String, dynamic> json) =>
      FileSettings.fromPath(
        json['path'] as String,
        name: json['name'] as String,
        enabled: json['isEnabled'] is bool ? json['isEnabled'] as bool : null,
        tts: json['isTts'] is bool ? json['isTts'] as bool : null,
        discord: json['isDiscord'] is bool ? json['isDiscord'] as bool : null,
      );

  Map<String, dynamic> toJson() => {
        'path': path,
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
