import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../main/settings/settings_box.dart';

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
  Map<String, String> getPaths() {
    final paths = <String, String>{};

    final List<String> directories = Directory(_defaultPath)
        .listSync()
        .whereType<Directory>()
        .map((directory) => directory.path)
        .toList();

    for (final directory in directories) {
      final String path = p.join(directory, 'logs', 'latest.log');

      if (File(path).existsSync()) paths[p.basename(directory)] = path;
    }

    return paths;
  }
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
  Map<String, String> getPaths() {
    final paths = <String, String>{};

    final String path = p.join(_defaultPath, 'logs', 'latest.log');
    if (File(path).existsSync()) paths['Default'] = path;

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

/// The MultiMC launcher.
class MultiMC extends Launcher {
  /// The MultiMC launcher.
  const MultiMC();

  static const _exeName = 'MultiMC.exe';

  @override
  String get name => 'MultiMC';

  @override
  AssetImage get icon => const AssetImage('assets/launchers/multimc.ico');

  @override
  String get _defaultPath {
    String? path = SettingsBox.multiMCPath;

    if (path != null && File(p.join(path, _exeName)).existsSync()) return path;

    path = null;
    final String result = Process.runSync(
      'PowerShell.exe',
      [
        'Get-Process',
        name,
        '|',
        'Select-Object',
        'Path',
      ],
    ).stdout;

    final List<String> split = const LineSplitter().convert(result);
    if (split.length > 3) {
      path = split[3].trim();
      if (File(path).existsSync()) path = p.dirname(path);
    }

    SettingsBox.multiMCPath = path;
    return path ?? '';
  }

  @override
  bool get isValid => _defaultPath.isNotEmpty;

  @override
  Map<String, String> getPaths() {
    final paths = <String, String>{};

    final List<String> directories =
        Directory(p.join(_defaultPath, 'instances'))
            .listSync()
            .whereType<Directory>()
            .map((directory) => directory.path)
            .toList();

    for (final directory in directories) {
      final String path = p.join(directory, '.minecraft', 'logs', 'latest.log');

      if (File(path).existsSync()) paths[p.basename(directory)] = path;
    }

    return paths;
  }
}
