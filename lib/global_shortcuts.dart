import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalShortcuts extends StatelessWidget {
  const GlobalShortcuts({
    super.key,
    required this.child,
    required this.changePage,
  });

  final Widget child;
  final Function changePage;

  static const ctrlO = SingleActivator(LogicalKeyboardKey.keyO, control: true);
  static const ctrlQ = SingleActivator(LogicalKeyboardKey.keyQ, control: true);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        ctrlO: () => changePage(true),
        ctrlQ: () => appWindow.close(),
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
