import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// A widget that provides a statically accessable toasts. The Toaster widget
/// must be placed in the widget tree after the FToastBuilder widget.
///
/// Optionally, both widgets can be placed in the builder of the MaterialApp:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     child = FToastBuilder()(context, Toaster(child));
///     return child;
///   },
///   home: HomePage(),
/// );
/// ```
class Toaster extends StatefulWidget {
  /// A widget that provides a statically accessable toasts. The Toaster widget
  /// must be placed in the widget tree after the FToastBuilder widget.
  ///
  /// Optionally, both widgets can be placed in the builder of the MaterialApp:
  /// ```dart
  /// MaterialApp(
  ///   builder: (context, child) {
  ///     child = FToastBuilder()(context, Toaster(child));
  ///     return child;
  ///   },
  ///   home: HomePage(),
  /// );
  /// ```
  const Toaster(
    Widget child, {
    super.key,
  }) : _child = child;

  final Widget _child;

  static late final FToast _fToast;
  static late Color _color;

  @override
  State<Toaster> createState() => _ToasterState();

  /// Shows a toast with the given message. The toast will be displayed at the
  /// location of the Toaster widget in the tree.
  ///
  /// Both the FToastBuilder and the Toaster widgets must be in the widget tree.
  static void showToast(String msg) {
    final Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: _color,
      ),
      child: Text(msg),
    );

    _fToast.showToast(
      child: toast,
      positionedToastBuilder: (context, child, gravity) => Positioned(
        left: 0,
        right: 0,
        bottom: 20,
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
  Widget build(BuildContext context) => widget._child;
}
