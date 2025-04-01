import 'package:flutter/material.dart';

/// A service for showing dialogs.
class DialogService {
  static BuildContext? _context;

  /// Shows a dialog in the center of the DialogProvider widget.
  static Future<void> showDialogElsewhere({
    required Widget Function(BuildContext) builder,
  }) async {
    // Send error when context has not been initialized
    if (_context == null) {
      throw Exception('DialogProvider must first be used in the tree.');
    }

    await showDialog(
      context: _context!,
      builder: builder,
    );
  }
}

/// A provider for the DialogService.
class DialogProvider extends StatefulWidget {
  /// A provider for the DialogService.
  const DialogProvider({
    required Widget child,
    super.key,
  }) : _child = child;

  final Widget _child;

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
    return widget._child;
  }
}
