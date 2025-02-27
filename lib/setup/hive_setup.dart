import 'dart:io';
import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../instance/instance_manager.dart';

class HiveSetup {
  static Future<void> setup() async {
    final Directory dir = await getApplicationSupportDirectory();
    Hive.defaultDirectory = dir.path;
    Hive.registerAdapter(
      'HiveOffset',
      (final dynamic json) => HiveOffset.fromJson(json as Map<String, dynamic>),
    );
    Hive.registerAdapter(
      'HiveSize',
      (final dynamic json) => HiveSize.fromJson(json as Map<String, dynamic>),
    );
    Hive.registerAdapter(
      'InstanceInfo',
      (final dynamic json) =>
          InstanceInfo.fromJson(json as Map<String, dynamic>),
    );
  }

  // TODO: Make all interactions with hive into a class
  // TODO: In general, clean up random string literals

  static Box settingsBox() => Hive.box(name: 'settings');
  static Box instancesBox() => Hive.box(name: 'instances');
}

class HiveOffset extends Offset {
  HiveOffset(super.dx, super.dy);
  HiveOffset.fromOffset(final Offset offset) : super(offset.dx, offset.dy);

  factory HiveOffset.fromJson(final Map<String, dynamic> json) => HiveOffset(
        json['dx'] as double,
        json['dy'] as double,
      );

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};
}

class HiveSize extends Size {
  HiveSize(super.width, super.height);
  HiveSize.fromSize(final Size size) : super(size.width, size.height);

  factory HiveSize.fromJson(final Map<String, dynamic> json) => HiveSize(
        json['width'] as double,
        json['height'] as double,
      );

  Map<String, dynamic> toJson() => {'width': width, 'height': height};
}
