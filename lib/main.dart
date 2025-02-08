import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:minecraft_to_speech/file_page.dart';
import 'package:minecraft_to_speech/global_shortcuts.dart';
import 'package:minecraft_to_speech/settings_page.dart';
import 'package:window_manager/window_manager.dart';

import 'top_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    backgroundColor: Colors.transparent,
    title: "Minecraft To Speech",
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    // await windowManager.focus();
  });

  runApp(const MainApp());

  doWhenWindowReady(() {
    appWindow.size = Size(800, 500);
    appWindow.minSize = Size(600, 450);
    appWindow.alignment = Alignment.center;
  });
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool isSettings = false;

  void changePage(isSettings) {
    setState(() {
      this.isSettings = isSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MTS",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0x00204969),
          brightness: Brightness.dark,
        ),
      ),
      home: GlobalShortcuts(
        changePage: changePage,
        child: Scaffold(
          appBar: TopBar(
            isSettings: isSettings,
            changePage: changePage,
          ),
          body: isSettings ? SettingsPage() : FilePage(),
        ),
      ),
    );
  }
}
