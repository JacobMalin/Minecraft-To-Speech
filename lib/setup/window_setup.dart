import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:minecraft_to_speech/setup/hive_setup.dart';
import 'package:win32/win32.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class WindowSetup {
  static mainPreRunApp() {
    var settingsBox = Hive.box(name: 'settings');
    HiveOffset? startPosition = settingsBox['position'];
    HiveSize? startSize = settingsBox['size'];
    bool? startIsMaximized = settingsBox['isMaximized'];

    WindowOptions windowOptions = WindowOptions(
      title: "Minecraft To Speech",
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      appWindow.minSize = Size(500, 260);
      appWindow.size = startSize ?? Size(500, 260);
      // Must be after size
      if (startPosition != null) appWindow.position = startPosition as Offset;

      // Check if window has landed offscreen
      if (!_isWindowOnValidMonitor()) appWindow.alignment = Alignment.center;

      if (startIsMaximized != null && startIsMaximized) {
        appWindow.alignment = Alignment.center;
        appWindow.size = Size(500, 260); // Set starting size small
        appWindow.maximize();
      }

      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  static process() {
    WindowOptions windowOptions = WindowOptions(
      title: "Log Processing",
      size: Size(350, 200),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      await WindowManagerPlus.current.setResizable(false);
    });
  }

  static bool _isWindowOnValidMonitor() {
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) return false;

    final monitor =
        MonitorFromWindow(hwnd, MONITOR_FROM_FLAGS.MONITOR_DEFAULTTONULL);
    return monitor != 0; // If 0, the window is offscreen
  }

  static Future<void> focusAndBringToFront() async {
    await WindowManagerPlus.current.setAlwaysOnTop(true);
    await WindowManagerPlus.current.setAlwaysOnTop(false);
    await WindowManagerPlus.current.focus();
  }
}

class WindowWatcher extends StatefulWidget {
  const WindowWatcher(
    this.child, {
    super.key,
  });

  final Widget child;

  @override
  State<WindowWatcher> createState() => _WindowWatcherState();
}

class _WindowWatcherState extends State<WindowWatcher> with WindowListener {
  @override
  void initState() {
    super.initState();

    WindowManagerPlus.current.addListener(this);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }

  @override
  void onWindowMoved([int? windowId]) async {
    var settingsBox = Hive.box(name: 'settings');

    HiveOffset pos =
        HiveOffset.fromOffset(await WindowManagerPlus.current.getPosition());
    settingsBox['position'] = pos;

    HiveSize size =
        HiveSize.fromSize(await WindowManagerPlus.current.getSize());
    settingsBox['size'] = size;
  }

  @override
  void onWindowResized([int? windowId]) async {
    var settingsBox = Hive.box(name: 'settings');

    HiveSize size =
        HiveSize.fromSize(await WindowManagerPlus.current.getSize());
    settingsBox['size'] = size;
  }

  @override
  void onWindowFocus([int? windowId]) {
    // Make sure to call once.
    setState(() {});
  }

  @override
  void onWindowMaximize([int? windowId]) {
    var settingsBox = Hive.box(name: 'settings');
    settingsBox['isMaximized'] = true;
  }

  @override
  void onWindowUnmaximize([int? windowId]) {
    var settingsBox = Hive.box(name: 'settings');
    settingsBox['isMaximized'] = false;
  }
}
