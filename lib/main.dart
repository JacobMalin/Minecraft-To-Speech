import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'instance/instance_model.dart';
import 'instance/instance_page.dart';
import 'process/process_controller.dart';
import 'process/process_window.dart';
import 'settings/settings_model.dart';
import 'settings/settings_page.dart';
import 'setup/hive_setup.dart';
import 'setup/theme_setup.dart';
import 'setup/window_setup.dart';
import 'toaster.dart';
import 'top_bar/top_bar.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line
  await WindowManagerPlus.ensureInitialized(
    args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0,
  );

  // Hive setup
  await HiveSetup.setup();

  if (args.length >= 3 && args[1] == WindowType.process) {
    final List<String> paths = [...jsonDecode(args[2])];

    WindowSetup.process();

    runApp(
      ProcessWindow(paths: paths),
    );
  } else {
    WindowSetup.main();

    // Start application
    runApp(const MainApp());
  }
}

/// The main application.
class MainApp extends StatefulWidget {
  /// The main application.
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(
          create: (_) => SettingsModel(),
        ),
        ChangeNotifierProvider<InstanceModel>(
          create: (_) => InstanceModel(),
        ),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Minecraft To Speech',
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: settings.themeMode,
            builder: (context, child) {
              child = WindowWatcher(child!);
              child = ProcessController(child);
              child = FToastBuilder()(context, Toaster(child));

              return child;
            },
            home: Scaffold(
              appBar: const MainTopBar(),
              body: Consumer<SettingsModel>(
                builder: (context, settings, child) => settings.isSettings
                    ? const SettingsPage()
                    : const InstancePage(),
              ),
            ),
          );
        },
      ),
    );
  }
}
