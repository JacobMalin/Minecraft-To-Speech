import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../file/file_filter.dart';
import '../file/file_model.dart';
import '../settings/settings_model.dart';
import '../setup/theme_setup.dart';
import '../top_bar/top_bar.dart';

class ProcessWindow extends StatefulWidget {
  const ProcessWindow({
    super.key,
    required this.args,
  });

  final Map args;

  @override
  State<ProcessWindow> createState() => _ProcessWindowState();
}

class _ProcessWindowState extends State<ProcessWindow> {
  @override
  void initState() {
    super.initState();

    process(widget.args['paths'].cast<String>());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
        ChangeNotifierProvider<FileModel>(create: (_) => FileModel()),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Log Processing",
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: settings.themeMode,
            home: Scaffold(
              appBar: ProcessTopBar(),
              body: Center(
                child: Builder(
                  builder: (context) {
                    return Text(
                      'Process Window',
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static process(List<String> paths) {
    final futures = paths.map(_processFile).wait;

    // If process finished quickly, report back to the main window
  }

  static Future<void> _processFile(String? path) async {
    final inFile = File(path!);

    final pathWithoutExt = p.withoutExtension(path);
    final extension = p.extension(path);
    final outFile = File("$pathWithoutExt-cleaned$extension");

    if (!(await inFile.exists()) || await outFile.exists()) return;

    final lines = await inFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where(FileFilter.onlyChat)
        .map(FileFilter.commonMap)
        .map(FileFilter.discordMap)
        .toList();

    await outFile.writeAsString(lines.join('\n'));
  }
}
