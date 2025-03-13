import 'dart:io';

import 'package:flutter/material.dart';
import 'package:velopack_flutter/velopack_flutter.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'setup/hive_setup.dart';
import 'setup/window_setup.dart';

void main(List<String> args) async {
  // Velopack setup
  await RustLib.init();

  final veloCommands = [
    '--veloapp-install',
    '--veloapp-updated',
    '--veloapp-obsolete',
    '--veloapp-uninstall',
  ];
  if (veloCommands.any((cmd) => args.contains(cmd))) {
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup
  await HiveSetup.setup();

  final int windowId = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
  await WindowManagerPlus.ensureInitialized(windowId);

  // Start app
  WindowSetup.run(args);
}
