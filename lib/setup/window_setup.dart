import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../settings/settings_model.dart';

/// Setup for the application window.
class WindowSetup {
  /// Setup for the main window that is run before the application starts.
  static void main() {
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
        appWindow.minSize = const Size(500, 260);
        appWindow.size = startSize ?? const Size(500, 260);
        // Must be after size
        if (startPosition != null) appWindow.position = startPosition;

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

  /// Setup for the log processing window that is run before the application
  /// starts.
  static void process() {
    const windowOptions = WindowOptions(
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

  /// Focus and bring the window to the front. This is useful because just
  /// focusing the window may not bring it to the front.
  static Future<void> focusAndBringToFront([int? windowId]) async {
    final WindowManagerPlus window = windowId != null
        ? WindowManagerPlus.fromWindowId(windowId)
        : WindowManagerPlus.current;

    await window.setAlwaysOnTop(true);
    await window.setAlwaysOnTop(false);
    await window.focus();
  }
}

/// A widget that watches the window for changes and saves them to the settings.
class WindowWatcher extends StatefulWidget {
  /// A widget that watches the window for changes and saves them to the
  /// settings.
  const WindowWatcher(
    this.child, {
    super.key,
  });

  /// The child widget.
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
  Widget build(BuildContext context) => widget.child;

  @override
  Future<void> onWindowMoved([int? windowId]) async {
    SettingsBox.position = await WindowManagerPlus.current.getPosition();
    SettingsBox.size = await WindowManagerPlus.current.getSize();
  }

  @override
  Future<void> onWindowResized([int? windowId]) async {
    SettingsBox.size = await WindowManagerPlus.current.getSize();
  }

  @override
  void onWindowFocus([int? windowId]) {
    // Make sure to call once.
    setState(() {});
  }

  @override
  void onWindowMaximize([int? windowId]) {
    SettingsBox.isMaximized = true;
  }

  @override
  void onWindowUnmaximize([int? windowId]) {
    SettingsBox.isMaximized = false;
  }
}

/// Types of windows that can be created.
class WindowType {
  /// A process window.
  // Must start with a char between '0-9' and '['
  static const process = 'Process';
}
