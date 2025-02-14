import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'file/file_settings.dart';
import 'file/file_theme.dart';
import 'file/file_page.dart';
import 'file/file_model.dart';
import 'hive_adapter.dart';
import 'global_shortcuts.dart';
import 'settings_page.dart';
import 'top_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup
  final dir = await getApplicationSupportDirectory();
  Hive.defaultDirectory = dir.path;
  Hive.registerAdapter('HiveOffset',
      (dynamic json) => HiveOffset.fromJson(json as Map<String, dynamic>));
  Hive.registerAdapter('HiveSize',
      (dynamic json) => HiveSize.fromJson(json as Map<String, dynamic>));
  Hive.registerAdapter('FileSettings',
      (dynamic json) => FileSettings.fromJson(json as Map<String, dynamic>));

  // Setup window manager
  await windowManager.ensureInitialized();

  // Start application
  runApp(const MainApp());

  // Window setup 2 (Must be after runApp)
  var windowBox = Hive.box(name: 'window');
  HiveOffset? startPosition = windowBox.get('position');
  HiveSize? startSize = windowBox.get('size');
  bool? startIsMaximized = windowBox.get('isMaximized');

  doWhenWindowReady(() {
    appWindow.title = "Minecraft To Speech";
    appWindow.minSize = Size(600, 450);

    appWindow.size = startSize ?? Size(800, 500);
    // Must be after size
    if (startPosition != null) appWindow.position = startPosition;

    if (startIsMaximized != null && startIsMaximized) appWindow.maximize();

    appWindow.show(); // Starts hidden to make less ugly
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
  void onWindowMoved() async {
    var windowBox = Hive.box(name: 'window');
    HiveOffset pos = HiveOffset.fromOffset(await windowManager.getPosition());
    windowBox['position'] = pos;
  }

  @override
  void onWindowResized() async {
    var windowBox = Hive.box(name: 'window');
    HiveSize size = HiveSize.fromSize(await windowManager.getSize());
    windowBox['size'] = size;
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
  }

  @override
  void onWindowMaximize() {
    var windowBox = Hive.box(name: 'window');
    windowBox['isMaximized'] = true;
  }

  @override
  void onWindowUnmaximize() {
    var windowBox = Hive.box(name: 'window');
    windowBox['isMaximized'] = false;
  }
}
