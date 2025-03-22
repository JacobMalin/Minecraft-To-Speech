import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../../setup/discord_model.dart';
import 'instance_model.dart';
import 'log_filter.dart';
import 'log_river.dart';
import 'tts_queue.dart';

/// Manages a minecraft instance. This includes the log streams and instance
/// info.
class InstanceController {
  /// Creates a controller for a minecraft instance.
  InstanceController(this.path, notifyListeners)
      : _notifyListeners = notifyListeners {
    _logRiver = LogRiver(
      path,
      notifyListeners: _notifyListeners,
      instance: this,
    );

    // Add path info to box if it doesn't exist
    if (!InstanceBox.infos.containsKey(path)) {
      InstanceBox.infos[path] = InstanceInfo.fromPath(path);
    }

    Future<void> initLogSubscriptions() async {
      _logRiver
        // UI stream
        ..addSubscription(
          map: LogFilter.uiMap,
          isEnabled: () => isEnabled,
          onData: (line) {
            messages.insert(0, line);
            _notifyListeners();
          },
        )

        // TTS stream
        ..addSubscription(
          map: LogFilter.ttsMap,
          isEnabled: () => isEnabled && isTts,
          onData: _tts.speak,
          onCancel: _tts.clear,
        )

        // Discord stream
        ..addSubscription(
          map: LogFilter.discordMap,
          isEnabled: () => isEnabled && isDiscord,
          onData: _discord.send,
          onCancel: _discord.clear,
        );
    }

    unawaited(initLogSubscriptions());
  }

  /// The path to the "latest.log" file of the instance.
  String path;

  /// The chat messages that have been received during this session. This is
  /// empty on boot.
  final List<String> messages = [];

  late final LogRiver _logRiver;
  final VoidCallback _notifyListeners;
  final _tts = TtsQueue();
  final _discord = DiscordModel();

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

  /// Delete all stored persistent data.
  void cleanBox() => InstanceBox.infos.delete(path);

  /// Destroy the instance controller. This will close all streams.
  Future<void> destroy() async {
    cleanBox();
    await _logRiver.destroy();
  }

  /// Update the instance with new data. This will update the persistent data
  /// and the streams.
  Future<void> updateWith({
    String? name,
    String? path,
    bool? enabled,
    bool? tts,
    bool? discord,
  }) async {
    final InstanceInfo info = this.info; // Needs to be info before path change

    if (path != null) {
      cleanBox();
      this.path = path;

      await _logRiver.divertRiver(path);
    }

    InstanceBox.infos[this.path] = info.copyWith(
      name: name,
      enabled: enabled,
      tts: tts,
      discord: discord,
    );

    await _logRiver.checkEnabled();
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
  factory InstanceInfo.fromPath(
    String path, {
    name,
    enabled = true,
    tts = true,
    discord = false,
  }) =>
      InstanceInfo._fromName(
        name ?? instanceDirectoryName(path) ?? path,
        enabled: enabled,
        tts: tts,
        discord: discord,
      );

  const InstanceInfo._fromName(
    this.name, {
    enabled = true,
    tts = true,
    discord = false,
  })  : isEnabled = enabled,
        isTts = tts,
        isDiscord = discord;

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
  final String name;

  /// Whether the instance is enabled. Disabled instances will not consume chat.
  final bool isEnabled;

  /// Whether the instance should use text-to-speech.
  final bool isTts;

  /// Whether the instance should use send chat messages to Discord.
  final bool isDiscord;

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

  /// Creates a copy of the instance info with new data.
  InstanceInfo copyWith({
    String? name,
    bool? enabled,
    bool? tts,
    bool? discord,
  }) =>
      InstanceInfo._fromName(
        name ?? this.name,
        enabled: enabled ?? isEnabled,
        tts: tts ?? isTts,
        discord: discord ?? isDiscord,
      );
}
