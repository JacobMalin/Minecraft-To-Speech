import 'dart:async';
import 'dart:convert';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../main/instance/tts_model.dart';
import '../main/main_app.dart';
import '../main/settings/settings_box.dart';
import '../process/process_app.dart';

/// Setup for the application window.
class WindowSetup {
  /// The minimum size of the mainWindow.
  static const minSize = Size(450, 250);

  /// Starts the app based on the given arguments.
  static Future<void> run(List<String> args) async {
    final int windowId = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
    await WindowManagerPlus.ensureInitialized(windowId);

    if (args.isEmpty) {
      WindowSetup.main();

      runApp(const MainApp());
    } else if (args.length >= 3 && args[1] == WindowType.process) {
      final List<String> paths = [...jsonDecode(args[2])];

      WindowSetup.process();

      runApp(ProcessApp(paths));
    }
  }

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
        appWindow.minSize = minSize;
        appWindow.size = startSize ?? minSize;
        // Must be after size
        if (startPosition != null) appWindow.position = startPosition;

        // Check if window has landed offscreen
        if (!_isWindowOnValidMonitor()) appWindow.alignment = Alignment.center;

        if (startIsMaximized != null && startIsMaximized) {
          appWindow.alignment = Alignment.center;
          appWindow.size = minSize; // Set starting size small
          appWindow.maximize();
        }

        await WindowManagerPlus.current.setPreventClose(true);

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
class WindowSetupWatcher extends StatefulWidget {
  /// A widget that watches the window for changes and saves them to the
  /// settings.
  const WindowSetupWatcher(
    Widget child, {
    super.key,
  }) : _child = child;

  final Widget _child;

  @override
  State<WindowSetupWatcher> createState() => _WindowSetupWatcherState();
}

class _WindowSetupWatcherState extends State<WindowSetupWatcher>
    with WindowListener {
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
  Widget build(BuildContext context) => widget._child;

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

  @override
  Future<void> onWindowClose([int? windowId]) async {
    final bool isPreventClose =
        await WindowManagerPlus.current.isPreventClose();
    if (isPreventClose) {
      await WindowManagerPlus.current.hide();
      await TtsModel().destroy();
      await WindowManagerPlus.current.destroy();
    }
  }
}

/// Types of windows that can be created.
class WindowType {
  // All types must start with a char between '0-9' and '[' as a limitation of
  // the WindowManagerPlus plugin. This is because the plugin uses a set to pass
  // arguments to the window, and sorts those arguments by their first
  // character.

  /// A process window.
  static const process = 'Process';
}
