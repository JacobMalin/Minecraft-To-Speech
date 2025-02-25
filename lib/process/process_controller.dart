import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../setup/window_setup.dart';

class ProcessController extends StatefulWidget {
  const ProcessController(
    this.child, {
    super.key,
  });

  final Widget child;

  @override
  State<ProcessController> createState() => _ProcessControllerState();

  static process() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: "Select Minecraft Log File to Process",
      type: FileType.custom,
      allowedExtensions: ['log'],
      allowMultiple: true,
    );

    WindowSetup.focusAndBringToFront();

    if (result == null) return; // If the user cancels the prompt, exit

    await WindowManagerPlus.createWindow([
      'process',
      jsonEncode({
        'paths': result.paths,
      })
    ]);
  }
}

class _ProcessControllerState extends State<ProcessController>
    with WindowListener {
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);

    fToast = FToast();
    fToast.init(context);
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
  Future<dynamic> onEventFromWindow(
      String eventName, int fromWindowId, dynamic arguments) async {
    if (eventName == 'quickProcessSucess') {
      final logCount = arguments as int;

      final plural = logCount == 1 ? "" : "s";
      Widget toast = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Text('Log$plural processed successfully!'),
      );

      fToast.showToast(
        child: toast,
        positionedToastBuilder: (context, child, gravity) => Positioned(
          left: 0,
          right: 0,
          bottom: 20.0,
          child: child,
        ),
        toastDuration: Duration(seconds: 3),
        isDismissible: true,
      );
    }
  }
}
