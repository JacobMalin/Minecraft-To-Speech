import 'package:flutter/material.dart';
import 'package:python_ffi/python_ffi.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'main/settings/settings_box.dart';
import 'setup/hive_setup.dart';
import 'setup/window_setup.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await PythonFfi.instance.initialize();

  // Hive setup
  await HiveSetup.setup();

  // Velopack setup
  await VelopackModel.setup(args);

  final int windowId = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
  await WindowManagerPlus.ensureInitialized(windowId);

  // Start app
  WindowSetup.run(args);
}
