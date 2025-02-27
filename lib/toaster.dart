import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Toaster extends StatefulWidget {
  const Toaster(
    this.child, {
    super.key,
  });

  final Widget child;

  static late final FToast _fToast;
  static late Color _color;

  @override
  State<Toaster> createState() => _ToasterState();

  static void showToast(final String msg) {
    final Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: _color,
      ),
      child: Text(msg),
    );

    _fToast.showToast(
      child: toast,
      positionedToastBuilder: (final context, final child, final gravity) =>
          Positioned(
        left: 0,
        right: 0,
        bottom: 20.0,
        child: child,
      ),
      toastDuration: const Duration(seconds: 3),
      isDismissible: true,
    );
  }
}

class _ToasterState extends State<Toaster> {
  @override
  void initState() {
    super.initState();

    Toaster._fToast = FToast().init(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Toaster._color = Theme.of(context).colorScheme.secondaryContainer;
  }

  @override
  Widget build(final BuildContext context) {
    return widget.child;
  }
}
