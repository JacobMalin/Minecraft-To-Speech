import 'dart:io';
import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../instance/instance_manager.dart';

/// A class to set up hive.
class HiveSetup {
  /// Perform hive setup. This method registers the adapters for the hive types
  /// and sets the default hive directory.
  ///
  /// This should be called before any other hive interactions.
  static Future<void> setup() async {
    final Directory dir = await getApplicationSupportDirectory();
    Hive.defaultDirectory = dir.path;
    Hive.registerAdapter(
      'HiveOffset',
      (dynamic json) => HiveOffset.fromJson(json as Map<String, dynamic>),
    );
    Hive.registerAdapter(
      'HiveSize',
      (dynamic json) => HiveSize.fromJson(json as Map<String, dynamic>),
    );
    Hive.registerAdapter(
      'InstanceInfo',
      (dynamic json) => InstanceInfo.fromJson(json as Map<String, dynamic>),
    );
  }
}

/// A class to store an offset in hive.
class HiveOffset extends Offset {
  /// Creates an offset that can be stored in hive.
  HiveOffset(super.dx, super.dy);

  /// Creates an offset that can be stored in hive.
  HiveOffset.fromOffset(Offset offset) : super(offset.dx, offset.dy);

  /// Creates a hive offset from a json object. This is used to recall
  /// persistent data.
  factory HiveOffset.fromJson(Map<String, dynamic> json) => HiveOffset(
        json['dx'] as double,
        json['dy'] as double,
      );

  /// Converts the hive offset to a json object. This is used to store
  /// persistent data.
  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};
}

/// A class to store a size in hive.
class HiveSize extends Size {
  /// Creates a size that can be stored in hive.
  HiveSize(super.width, super.height);

  /// Creates a size that can be stored in hive.
  HiveSize.fromSize(Size size) : super(size.width, size.height);

  /// Creates a hive size from a json object. This is used to recall persistent
  /// data.
  factory HiveSize.fromJson(Map<String, dynamic> json) => HiveSize(
        json['width'] as double,
        json['height'] as double,
      );

  /// Converts the hive size to a json object. This is used to store persistent
  /// data.
  Map<String, dynamic> toJson() => {'width': width, 'height': height};
}
