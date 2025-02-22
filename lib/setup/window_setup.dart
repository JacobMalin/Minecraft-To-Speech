import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:minecraft_to_speech/setup/hive_setup.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

class WindowSetup {
  static preRunApp() async {
    // Must wait for window manager setup
    await windowManager.ensureInitialized();
  }

  static postRunApp() {
    var settingsBox = Hive.box(name: 'settings');
    HiveOffset? startPosition = settingsBox['position'];
    HiveSize? startSize = settingsBox['size'];
    bool? startIsMaximized = settingsBox['isMaximized'];

    doWhenWindowReady(() {
      appWindow.title = "Minecraft To Speech";
      appWindow.minSize = Size(500, 260);

      appWindow.size = startSize ?? Size(500, 260);
      // Must be after size
      if (startPosition != null) appWindow.position = startPosition as Offset;

      // Check if window has landed offscreen
      if (!_isWindowOnValidMonitor()) appWindow.alignment = Alignment.center;

      if (startIsMaximized != null && startIsMaximized) appWindow.maximize();

      appWindow.show(); // Starts hidden to make less ugly
    });
  }

  static bool _isWindowOnValidMonitor() {
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) return false;

    final monitor =
        MonitorFromWindow(hwnd, MONITOR_FROM_FLAGS.MONITOR_DEFAULTTONULL);
    return monitor != 0; // If 0, the window is offscreen
  }

  static void focusAfterPicker() async {
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.focus();
  }
}

class WindowWatcher extends StatefulWidget {
  const WindowWatcher({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<WindowWatcher> createState() => _WindowWatcherState();
}

class _WindowWatcherState extends State<WindowWatcher> with WindowListener {
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
    return Container(
      child: widget.child,
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
