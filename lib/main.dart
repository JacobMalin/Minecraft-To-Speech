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

// TODO: Finish going through linters

void main(final List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line
  await WindowManagerPlus.ensureInitialized(
      args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0);

  // Hive setup
  await HiveSetup.setup();

  if (args.length >= 3 && args[1] == 'process') {
    final Map<String, dynamic> argTwo =
        args.length > 2 && args[2].isNotEmpty ? jsonDecode(args[2]) : const {};

    WindowSetup.process();

    runApp(ProcessWindow(
      args: argTwo,
    ));
  } else {
    WindowSetup.mainPreRunApp();

    // Start application
    runApp(const MainApp());
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(final BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(
          create: (final _) => SettingsModel(),
        ),
        ChangeNotifierProvider<InstanceModel>(
          create: (final _) => InstanceModel(),
        ),
      ],
      child: Consumer<SettingsModel>(
        builder: (final context, final settings, final child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Minecraft To Speech',
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: settings.themeMode,
            builder: (final context, child) {
              child = WindowWatcher(child!);
              child = ProcessController(child);
              child = FToastBuilder()(context, Toaster(child));

              return child;
            },
            home: Scaffold(
              appBar: const MainTopBar(),
              body: Consumer<SettingsModel>(
                builder: (final context, final settings, final child) =>
                    settings.isSettings
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
