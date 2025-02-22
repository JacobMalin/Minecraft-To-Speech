import 'package:flutter/material.dart';

class DialogService {
  static late final BuildContext _context;

  static showDialogElsewhere({required Widget Function(BuildContext) builder}) {
    // Send error when context has not been initialized
    try {
      _context;
    } catch (e) {
      throw Exception("DialogService must first be used in the tree.");
    }

    showDialog(
      context: _context,
      builder: builder,
      barrierColor: Colors.transparent,
    );
  }
}

class DialogProvider extends StatefulWidget {
  const DialogProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DialogProvider> createState() => _DialogProviderState();
}

class _DialogProviderState extends State<DialogProvider> {
  @override
  void initState() {
    super.initState();

    DialogService._context = context;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
