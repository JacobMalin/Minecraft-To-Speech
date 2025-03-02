import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

/// A model for the focus of the window.
class FocusModel extends ChangeNotifier {
  var _isFocused = false;

  /// Whether the window is focused.
  bool get isFocused => _isFocused;
  set isFocused(bool value) {
    _isFocused = value;
    notifyListeners();
  }
}

/// A widget that watches the focus of the window.
class FocusWatcher extends StatefulWidget {
  /// A widget that watches the focus of the window.
  const FocusWatcher(this.child, {super.key});

  /// The child widget.
  final Widget child;

  @override
  State<FocusWatcher> createState() => _FocusWatcherState();
}

class _FocusWatcherState extends State<FocusWatcher> with WindowListener {
  late final FocusModel _focusModel;

  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);

    _focusModel = Provider.of<FocusModel>(context, listen: false);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  Future<void> onWindowFocus([int? windowId]) async {
    _focusModel.isFocused = true;
  }

  @override
  Future<void> onWindowBlur([int? windowId]) async {
    _focusModel.isFocused = false;
  }
}
