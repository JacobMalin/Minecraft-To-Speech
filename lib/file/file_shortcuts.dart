import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'file_model.dart';

class FileShortcuts extends StatefulWidget {
  const FileShortcuts({
    super.key,
    required this.child,
  });

  final Widget child;

  static const delete = SingleActivator(LogicalKeyboardKey.delete);

  @override
  State<FileShortcuts> createState() => _FileShortcutsState();
}

class _FileShortcutsState extends State<FileShortcuts> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    final files = Provider.of<FileModel>(context, listen: false);

    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileModel>(builder: (context, files, _) {
      return Focus(
        onKeyEvent: (node, event) {
          print(_focusNode.hasFocus);
          if (_focusNode.hasPrimaryFocus &&
              event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.delete) files.remove();
          return KeyEventResult.ignored;
        },
        autofocus: true,
        canRequestFocus: true,
        child: KeyboardListener(
          focusNode: _focusNode,
          child: widget.child,
        ),
      );
    });
  }
}
