import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../main/settings/settings_box.dart';
import '../setup/focus_model.dart';
import '../setup/theme_setup.dart';
import '../top_bar/top_bar.dart';

/// The main app for the blacklist window.
class BlacklistApp extends StatefulWidget {
  /// The main app for the blacklist window.
  const BlacklistApp({super.key});

  /// The minimum size of the window.
  static const minSize = Size(350, 200);

  @override
  State<BlacklistApp> createState() => _BlacklistAppState();
}

class _BlacklistAppState extends State<BlacklistApp> {
  @override
  void initState() {
    super.initState();

    const windowOptions = WindowOptions(
      title: 'Blacklist',
      size: BlacklistApp.minSize,
      minimumSize: BlacklistApp.minSize,
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    unawaited(
      WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
        await WindowManagerPlus.current.show();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
        ChangeNotifierProvider<FocusModel>(create: (_) => FocusModel()),
      ],
      child: Selector<SettingsModel, ThemeMode>(
        selector: (_, settings) => settings.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Blacklist',
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: themeMode,
            builder: (context, child) => FocusWatcher(child!),
            home: const Scaffold(
              appBar: BlacklistTopBar(),
              body: BlacklistBody(),
            ),
          );
        },
      ),
    );
  }
}

/// The body of the blacklist window.
class BlacklistBody extends StatelessWidget {
  /// The body of the blacklist window.
  const BlacklistBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: Center(
            child: Text('BlacklistList'),
          ),
        ),
        Divider(
          thickness: 2,
          height: 0,
        ),
        SizedBox(
          height: 50,
          child: Center(
            child: Text('Options'),
          ),
        ),
      ],
    );
  }
}
