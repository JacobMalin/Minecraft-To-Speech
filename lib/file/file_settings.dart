import 'dart:io';

import 'package:path/path.dart' as p;

class FileSettings {
  final File file;
  final String name;
  bool enabled = false;

  FileSettings.fromPath(path, {this.enabled = false})
      : file = File(path),
        name = secondFolder(path) ?? path;

  get path => file.path;

  static secondFolder(path) {
    List<String> parts = p.split(path);

    return parts.length > 3 ? parts[parts.length - 3] : null;
  }
}
