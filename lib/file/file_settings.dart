import 'dart:io';

import 'package:path/path.dart' as p;

class FileSettings {
  final File file;
  final String name;
  bool isEnabled;

  FileSettings.fromPath(path, {name, isEnabled})
      : file = File(path),
        name = name ?? secondFolder(path) ?? path,
        isEnabled = isEnabled ?? false;

  factory FileSettings.fromJson(Map<String, dynamic> json) =>
      FileSettings.fromPath(
        json['path'] as String,
        name: json['name'] as String,
        isEnabled: json['isEnabled'] is bool ? json['isEnabled'] as bool : null,
      );

  Map<String, dynamic> toJson() => {'path': path, 'name': name, 'isEnabled': isEnabled};

  get path => file.path;

  static secondFolder(path) {
    List<String> parts = p.split(path);

    return parts.length > 3 ? parts[parts.length - 3] : null;
  }
}
