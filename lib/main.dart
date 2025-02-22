import 'package:flutter/material.dart';
import 'package:minecraft_to_speech/dialog_service.dart';
import 'package:provider/provider.dart';

import 'file/file_theme.dart';
import 'file/file_page.dart';
import 'file/file_model.dart';
import 'setup/hive_setup.dart';
import 'settings/settings_model.dart';
import 'settings/settings_page.dart';
import 'top_bar.dart';
import 'setup/window_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup
  await HiveSetup.setup();

  // Window setup 1
  await WindowSetup.preRunApp();

  // Start application
  runApp(const MainApp());

  // Window setup 2 (Must be after runApp)
  WindowSetup.postRunApp();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  final seedColor = const Color(0x00204969);

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

    return WindowWatcher(
        child: MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
        ChangeNotifierProvider<FileModel>(create: (_) => FileModel()),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: "MTS",
            theme: brightTheme,
            darkTheme: darkTheme,
            themeMode: settings.themeMode,
            home: Scaffold(
              appBar: child as PreferredSizeWidget,
              body: DialogProvider(
                child: settings.isSettings ? SettingsPage() : FilePage(),
              ),
            ),
          );
        },
        child: TopBar(),
      ),
    ));
  }
}
