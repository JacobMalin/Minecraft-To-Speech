import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../process/process_controller.dart';
import '../setup/focus_model.dart';
import '../setup/theme_setup.dart';
import '../setup/toaster.dart';
import '../setup/window_setup.dart';
import '../top_bar/top_bar.dart';
import 'instance/instance_model.dart';
import 'instance/instance_page.dart';
import 'settings/settings_model.dart';
import 'settings/settings_page.dart';

class MainApp implements Application {
  // TODO: check if args is correct
  run(List<String> args) {
    WindowSetup.main();

    runApp(const MainWindow());
  }
}

/// The main window.
class MainWindow extends StatefulWidget {
  /// The main window.
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
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
        ChangeNotifierProvider<FocusModel>(
          create: (_) => FocusModel(),
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
              child!;

              child = WindowSetupWatcher(child);
              child = FocusWatcher(child);
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
