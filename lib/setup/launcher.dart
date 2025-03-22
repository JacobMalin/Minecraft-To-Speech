import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// A minecraft launcher that minecraft instances can be added from.
abstract class Launcher {
  /// A minecraft launcher that minecraft instances can be added from.
  const Launcher();

  /// The name of the launcher.
  String get name;

  /// The icon of the launcher.
  AssetImage get icon;

  /// Whether the launcher exists on the system.
  bool get isValid => Directory(_defaultPath).existsSync();

  /// The default path to find launcher instances.
  String get _defaultPath;

  /// Get instance paths from the default path.
  List<String> getPaths() {
    final paths = <String>[];

    final List<String> directories = Directory(_defaultPath)
        .listSync()
        .whereType<Directory>()
        .map((directory) => directory.path)
        .toList();

    for (final directory in directories) {
      final String path = p.join(directory, 'logs', 'latest.log');

      if (File(path).existsSync()) paths.add(path);
    }

    return paths;
  }
}

/// The CurseForge launcher.
class CurseForge extends Launcher {
  /// The CurseForge launcher.
  const CurseForge();

  @override
  String get name => 'CurseForge';

  @override
  AssetImage get icon => const AssetImage('assets/launchers/curseforge.ico');

  @override
  String get _defaultPath => p.join(
        Platform.environment['USERPROFILE']!,
        'curseforge',
        'minecraft',
        'Instances',
      );
}

/// The default minecraft launcher.
class Minecraft extends Launcher {
  /// The default minecraft launcher.
  const Minecraft();

  @override
  String get name => 'Minecraft Launcher';

  @override
  AssetImage get icon => const AssetImage('assets/launchers/minecraft.ico');

  @override
  String get _defaultPath => p.join(
        Platform.environment['APPDATA']!,
        '.minecraft',
      );

  @override
  List<String> getPaths() {
    final paths = <String>[];

    final String path = p.join(_defaultPath, 'logs', 'latest.log');
    if (File(path).existsSync()) paths.add(path);

    return paths;
  }
}
