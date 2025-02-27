import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../setup/window_setup.dart';
import '../toaster.dart';

class ProcessController extends StatefulWidget {
  const ProcessController(
    this.child, {
    super.key,
  });

  final Widget child;

  static const quickSuccess = 'quickProcessSuccess';

  @override
  State<ProcessController> createState() => _ProcessControllerState();

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
      'process',
      jsonEncode({'paths': result.paths})
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
  Widget build(final BuildContext context) {
    return widget.child;
  }

  @override
  Future<dynamic> onEventFromWindow(
    final String eventName,
    final int fromWindowId,
    final dynamic arguments,
  ) async {
    if (eventName == ProcessController.quickSuccess) {
      final logCount = arguments as int;

      final plural = logCount == 1 ? '' : 's';

      Toaster.showToast('Log$plural processed successfully!');
    }
  }
}
