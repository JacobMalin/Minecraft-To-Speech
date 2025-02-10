import 'dart:ui';

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
