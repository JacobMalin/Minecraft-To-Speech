import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../file/file_manager.dart';

class HiveSetup {
  static setup() async {
    final dir = await getApplicationSupportDirectory();
    Hive.defaultDirectory = dir.path;
    Hive.registerAdapter('HiveOffset',
        (dynamic json) => HiveOffset.fromJson(json as Map<String, dynamic>));
    Hive.registerAdapter('HiveSize',
        (dynamic json) => HiveSize.fromJson(json as Map<String, dynamic>));
    Hive.registerAdapter('FileInfo',
        (dynamic json) => FileInfo.fromJson(json as Map<String, dynamic>));
  }
}

class HiveOffset extends Offset {
  HiveOffset(super.dx, super.dy);
  HiveOffset.fromOffset(Offset offset) : super(offset.dx, offset.dy);

  factory HiveOffset.fromJson(Map<String, dynamic> json) => HiveOffset(
        json['dx'] as double,
        json['dy'] as double,
      );

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};
}

class HiveSize extends Size {
  HiveSize(super.width, super.height);
  HiveSize.fromSize(Size size) : super(size.width, size.height);

  factory HiveSize.fromJson(Map<String, dynamic> json) => HiveSize(
        json['width'] as double,
        json['height'] as double,
      );

  Map<String, dynamic> toJson() => {'width': width, 'height': height};
}
