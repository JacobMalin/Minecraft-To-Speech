import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'main/main_app.dart';
import 'process/process_app.dart';
import 'setup/hive_setup.dart';
import 'setup/window_setup.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final int windowId = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
  await WindowManagerPlus.ensureInitialized(windowId);

  // Hive setup
  await HiveSetup.setup();

  // TODO: Polymorphise
  if (args.length >= 3 && args[1] == WindowType.process) {
    final List<String> paths = [...jsonDecode(args[2])];

    WindowSetup.process();

    runApp(ProcessApp(paths));
  } else {
    WindowSetup.main();

    runApp(const MainWindow());
  }
}
