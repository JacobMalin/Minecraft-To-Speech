import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minecraft_to_speech/file/file_model.dart';
import 'package:provider/provider.dart';

class GlobalShortcuts extends StatelessWidget {
  const GlobalShortcuts({
    super.key,
    required this.child,
    required this.changePage,
  });

  final Widget child;
  final Function changePage;

  static const delete = SingleActivator(LogicalKeyboardKey.delete);

  @override
  Widget build(BuildContext context) {
    return Consumer<FileModel>(
      builder: (context, files, _) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            delete: () => files.remove(),
          },
          child: Focus(
            autofocus: true,
            child: child,
          ),
        );
      }
    );
  }
}
