import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../process/process_controller.dart';
import '../setup/dialog_service.dart';
import '../setup/focus_model.dart';
import '../setup/theme_setup.dart';
import '../setup/toaster.dart';
import '../setup/window_setup.dart';
import '../top_bar/top_bar.dart';
import 'instance/instance_model.dart';
import 'instance/instance_page.dart';
import 'settings/settings_model.dart';
import 'settings/settings_page.dart';

/// The main window.
class MainApp extends StatefulWidget {
  /// The main window.
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
        ChangeNotifierProvider<InstanceModel>(create: (_) => InstanceModel()),
        ChangeNotifierProvider<FocusModel>(create: (_) => FocusModel()),
      ],
      child: Selector<SettingsModel, ThemeMode>(
        selector: (context, settings) => settings.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Minecraft To Speech',
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: themeMode,
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
              body: DialogProvider(
                child: Selector<SettingsModel, bool>(
                  selector: (context, settings) => settings.isSettings,
                  builder: (context, isSettings, child) =>
                      isSettings ? const SettingsPage() : const InstancePage(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
