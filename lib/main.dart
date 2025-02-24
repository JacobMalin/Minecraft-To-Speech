import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:minecraft_to_speech/process/process_window.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'file/file_model.dart';
import 'file/file_page.dart';
import 'setup/hive_setup.dart';
import 'setup/theme_setup.dart';
import 'setup/window_setup.dart';
import 'settings/settings_model.dart';
import 'settings/settings_page.dart';
import 'top_bar/top_bar.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line
  await WindowManagerPlus.ensureInitialized(
      args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0);

  // Hive setup
  await HiveSetup.setup();

  if (args.length >= 3 && args[1] == 'process') {
    final argument = args.length > 2 && args[2].isNotEmpty
        ? jsonDecode(args[2]) as Map<String, dynamic>
        : const {};

    WindowSetup.process();

    runApp(ProcessWindow(
      args: argument,
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
  Widget build(BuildContext context) {
    return WindowWatcher(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
          ChangeNotifierProvider<FileModel>(create: (_) => FileModel()),
        ],
        child: Consumer<SettingsModel>(
          builder: (context, settings, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: "Minecraft To Speech",
              theme: ThemeSetup.brightTheme,
              darkTheme: ThemeSetup.darkTheme,
              themeMode: settings.themeMode,
              home: Scaffold(
                appBar: child as PreferredSizeWidget,
                body: settings.isSettings ? SettingsPage() : FilePage(),
              ),
            );
          },
          child: MainTopBar(),
        ),
      ),
    );
  }
}
