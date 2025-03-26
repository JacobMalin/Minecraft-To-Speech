import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../process/process_controller.dart';
import '../setup/dialog_service.dart';
import '../setup/discord_model.dart';
import '../setup/focus_model.dart';
import '../setup/theme_setup.dart';
import '../setup/toaster.dart';
import '../setup/window_setup.dart';
import '../top_bar/top_bar.dart';
import 'instance/instance_model.dart';
import 'instance/instance_page.dart';
import 'settings/settings_box.dart';
import 'settings/settings_page.dart';

/// The main window.
class MainApp extends StatefulWidget {
  /// The main window.
  const MainApp({super.key});

  /// The minimum size of the mainWindow.
  static const minSize = Size(450, 250);

  @override
  State<MainApp> createState() => _MainAppState();

  /// Setup for the main window that is run before the application starts.
  static void setup() {
    final Offset? startPosition = SettingsBox.position;
    final Size? startSize = SettingsBox.size;
    final bool? startIsMaximized = SettingsBox.isMaximized;

    const windowOptions = WindowOptions(
      title: 'Minecraft To Speech',
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    unawaited(
      WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
        appWindow.minSize = minSize;
        appWindow.size = startSize ?? minSize;
        // Must be after size
        if (startPosition != null) appWindow.position = startPosition;

        // Check if window has landed offscreen
        if (!WindowSetup.isWindowOnValidMonitor()) {
          appWindow.alignment = Alignment.center;
        }

        if (startIsMaximized != null && startIsMaximized) {
          appWindow.alignment = Alignment.center;
          appWindow.size = minSize; // Set starting size small
          appWindow.maximize();
        }

        await WindowManagerPlus.current.setPreventClose(true);

        await WindowManagerPlus.current.show();
      }),
    );
  }
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
        ChangeNotifierProvider<InstanceModel>(create: (_) => InstanceModel()),
        ChangeNotifierProvider<VelopackModel>(create: (_) => VelopackModel()),
        ChangeNotifierProvider<DiscordModel>(create: (_) => DiscordModel()),
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
              // Load models immediately.
              Provider.of<VelopackModel>(context);
              Provider.of<DiscordModel>(context);

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
