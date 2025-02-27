import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:win32/win32.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'hive_setup.dart';

class WindowSetup {
  static void mainPreRunApp() {
    final Box settingsBox = HiveSetup.settingsBox();
    final HiveOffset? startPosition = settingsBox['position'];
    final HiveSize? startSize = settingsBox['size'];
    final bool? startIsMaximized = settingsBox['isMaximized'];

    final WindowOptions windowOptions = const WindowOptions(
      title: 'Minecraft To Speech',
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    unawaited(
      WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
        appWindow.minSize = const Size(500, 260);
        appWindow.size = startSize ?? const Size(500, 260);
        // Must be after size
        if (startPosition != null) appWindow.position = startPosition as Offset;

        // Check if window has landed offscreen
        if (!_isWindowOnValidMonitor()) appWindow.alignment = Alignment.center;

        if (startIsMaximized != null && startIsMaximized) {
          appWindow.alignment = Alignment.center;
          appWindow.size = const Size(500, 260); // Set starting size small
          appWindow.maximize();
        }

        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
      }),
    );
  }

  static void process() {
    final WindowOptions windowOptions = const WindowOptions(
      title: 'Log Processing',
      size: Size(350, 200),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    unawaited(
      WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
        await WindowManagerPlus.current.setResizable(false);
      }),
    );
  }

  static bool _isWindowOnValidMonitor() {
    final int hwnd = GetForegroundWindow();
    if (hwnd == 0) return false;

    final int monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONULL);
    return monitor != 0; // If 0, the window is offscreen
  }

  static Future<void> focusAndBringToFront([final int? windowId]) async {
    final WindowManagerPlus window = windowId != null
        ? WindowManagerPlus.fromWindowId(windowId)
        : WindowManagerPlus.current;

    await window.setAlwaysOnTop(true);
    await window.setAlwaysOnTop(false);
    await window.focus();
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
  Widget build(final BuildContext context) {
    return Container(
      child: widget.child,
    );
  }

  @override
  Future<void> onWindowMoved([final int? windowId]) async {
    final Box settingsBox = HiveSetup.settingsBox();

    final HiveOffset pos =
        HiveOffset.fromOffset(await WindowManagerPlus.current.getPosition());
    settingsBox['position'] = pos;

    final HiveSize size =
        HiveSize.fromSize(await WindowManagerPlus.current.getSize());
    settingsBox['size'] = size;
  }

  @override
  Future<void> onWindowResized([final int? windowId]) async {
    final Box settingsBox = HiveSetup.settingsBox();

    final HiveSize size =
        HiveSize.fromSize(await WindowManagerPlus.current.getSize());
    settingsBox['size'] = size;
  }

  @override
  void onWindowFocus([final int? windowId]) {
    // Make sure to call once.
    setState(() {});
  }

  @override
  void onWindowMaximize([final int? windowId]) {
    final Box settingsBox = HiveSetup.settingsBox();
    settingsBox['isMaximized'] = true;
  }

  @override
  void onWindowUnmaximize([final int? windowId]) {
    final Box settingsBox = HiveSetup.settingsBox();
    settingsBox['isMaximized'] = false;
  }
}
