import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:win32/win32.dart';

import 'file/file_settings.dart';
import 'file/file_theme.dart';
import 'file/file_page.dart';
import 'file/file_model.dart';
import 'hive_adapter.dart';
import 'file/file_shortcuts.dart';
import 'settings/settings_model.dart';
import 'settings/settings_page.dart';
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
  var settingsBox = Hive.box(name: 'settings');
  HiveOffset? startPosition = settingsBox['position'];
  HiveSize? startSize = settingsBox['size'];
  bool? startIsMaximized = settingsBox['isMaximized'];

  doWhenWindowReady(() {
    appWindow.title = "Minecraft To Speech";
    appWindow.minSize = Size(600, 450);

    appWindow.size = startSize ?? Size(800, 500);
    // Must be after size
    if (startPosition != null) appWindow.position = startPosition as Offset;

    // Check if window has landed offscreen
    if (!isWindowOnValidMonitor()) appWindow.alignment = Alignment.center;

    if (startIsMaximized != null && startIsMaximized) appWindow.maximize();

    appWindow.show(); // Starts hidden to make less ugly
  });
}

bool isWindowOnValidMonitor() {
  final hwnd = GetForegroundWindow();
  if (hwnd == 0) return false;

  final monitor =
      MonitorFromWindow(hwnd, MONITOR_FROM_FLAGS.MONITOR_DEFAULTTONULL);
  return monitor != 0; // If 0, the window is offscreen
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WindowListener {
  final seedColor = Color(0x00204969);

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
    var brightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
    ).copyWith(extensions: <ThemeExtension<dynamic>>[
      FileTheme.light(),
    ]);
    var darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[
        FileTheme.dark(),
      ],
    );

    return ChangeNotifierProvider<SettingsModel>(
      create: (_) => SettingsModel(),
      child: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: "MTS",
            theme: brightTheme,
            darkTheme: darkTheme,
            themeMode: settings.themeMode,
            home: child,
          );
        },
        child: ChangeNotifierProvider<FileModel>(
          create: (_) => FileModel(),
          child: Consumer<SettingsModel>(builder: (context, settings, child) {
            return Scaffold(
              appBar: TopBar(),
              body: settings.isSettings ? SettingsPage() : FilePage(),
            );
          }),
        ),
      ),
    );
  }

  @override
  void onWindowMoved() async {
    var settingsBox = Hive.box(name: 'settings');
    HiveOffset pos = HiveOffset.fromOffset(await windowManager.getPosition());
    settingsBox['position'] = pos;
  }

  @override
  void onWindowResized() async {
    var settingsBox = Hive.box(name: 'settings');
    HiveSize size = HiveSize.fromSize(await windowManager.getSize());
    settingsBox['size'] = size;
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
  }

  @override
  void onWindowMaximize() {
    var settingsBox = Hive.box(name: 'settings');
    settingsBox['isMaximized'] = true;
  }

  @override
  void onWindowUnmaximize() {
    var settingsBox = Hive.box(name: 'settings');
    settingsBox['isMaximized'] = false;
  }
}
