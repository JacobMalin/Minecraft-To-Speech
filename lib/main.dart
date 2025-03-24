import 'package:flutter/material.dart';

import 'main/settings/settings_box.dart';
import 'setup/hive_setup.dart';
import 'setup/window_setup.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup
  await HiveSetup.setup();

  // Velopack setup
  await VelopackModel.setup(args);

  // Start app
  await WindowSetup.run(args);
}
