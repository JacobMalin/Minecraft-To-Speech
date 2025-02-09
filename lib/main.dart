import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'file/file_theme.dart';
import 'file/file_page.dart';
import 'global_shortcuts.dart';
import 'file/file_model.dart';
import 'settings_page.dart';
import 'top_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    backgroundColor: Colors.transparent,
    title: "Minecraft To Speech",
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {});

  runApp(const MainApp());

  doWhenWindowReady(() {
    appWindow.size = Size(800, 500);
    appWindow.minSize = Size(600, 450);
  });
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WindowListener {
  bool isSettings = false;

  final seedColor = Color(0x00204969);

  void changePage(isSettings) {
    setState(() {
      this.isSettings = isSettings;
    });
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  void _init() async {
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MTS",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ).copyWith(extensions: <ThemeExtension<dynamic>>[
        FileTheme.light(),
      ]),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          FileTheme.dark(),
        ],
      ),
      themeMode: ThemeMode.system,
      home: ChangeNotifierProvider(
        create: (context) => FileModel(),
        child: GlobalShortcuts(
          changePage: changePage,
          child: Scaffold(
            appBar: TopBar(
              isSettings: isSettings,
              changePage: changePage,
            ),
            body: isSettings ? SettingsPage() : FilePage(),
          ),
        ),
      ),
    );
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      // Made the window not visible to the user
      windowManager.hide();

      // Save data
      // print(await windowManager.getPosition());
      // TODO: Save position
      // TODO: Save files
      // TODO: Save user settings

      // Kill for real
      await windowManager.destroy();
    }
  }
}
