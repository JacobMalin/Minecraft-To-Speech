import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../setup/toaster.dart';
import '../setup/window_setup.dart';

/// A controller for processing Minecraft logs.
class ProcessController extends StatefulWidget {
  /// A controller for processing Minecraft logs.
  const ProcessController(
    Widget child, {
    super.key,
  }) : _child = child;

  final Widget _child;

  @override
  State<ProcessController> createState() => _ProcessControllerState();

  /// Processes Minecraft logs. This will open a new process window. If the
  /// log(s) process quickly, a toast will appear instead of the new window.
  static Future<void> process() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Minecraft Log File to Process',
      type: FileType.custom,
      allowedExtensions: ['log'],
      allowMultiple: true,
    );

    await WindowSetup.focusAndBringToFront();

    if (result == null) return; // If the user cancels the prompt, exit

    await WindowManagerPlus.createWindow([
      WindowType.process,
      jsonEncode(result.paths),
    ]);
  }
}

class _ProcessControllerState extends State<ProcessController>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget._child;

  @override
  Future<dynamic> onEventFromWindow(
    String eventName,
    int fromWindowId,
    dynamic arguments,
  ) async {
    if (eventName == ProcessEvent.quickSuccess) {
      final logCount = arguments as int;

      final plural = logCount == 1 ? '' : 's';

      Toaster.showToast('Log$plural processed successfully!');
    }
  }
}

/// Events that can be sent from the process window.
class ProcessEvent {
  /// Event for when the process window finishes quickly.
  static const quickSuccess = 'quickSucess';

  /// The event name used when the process completes with no errors.
  static const success = 'success';
}
