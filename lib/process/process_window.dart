import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:smooth_list_view/smooth_list_view.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../file/file_filter.dart';
import '../file/file_model.dart';
import '../settings/settings_model.dart';
import '../setup/theme_setup.dart';
import '../setup/window_setup.dart';
import '../top_bar/top_bar.dart';
import 'process_controller.dart';

class ProcessWindow extends StatefulWidget {
  const ProcessWindow({
    super.key,
    required this.args,
  });

  final Map args;

  static const success = "Success";

  @override
  State<ProcessWindow> createState() => _ProcessWindowState();
}

class _ProcessWindowState extends State<ProcessWindow> {
  late final Future<List<String>> futures;
  late final int pathCount;

  @override
  void initState() {
    super.initState();

    final paths = widget.args['paths'].cast<String>();
    pathCount = paths.length;
    process(paths);
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
              body: ProcessBody(futures, pathCount),
            ),
          );
        },
      ),
    );
  }

  process(List<String> paths) async {
    var isCompleted = false;
    futures = paths.map(_processFile).wait.whenComplete(() {
      isCompleted = true;
    });

    // Wait a bit before showing the window, to prevent immediate sucess from
    // opening a window
    await Future.delayed(Duration(milliseconds: 400));

    // If process finished quickly, report back to the main window, unless there
    // was an error
    if (isCompleted) {
      final results = await futures;

      final sucessCount =
          results.where((result) => result == ProcessWindow.success).length;

      if (sucessCount == results.length) {
        var mainWindow = WindowManagerPlus.fromWindowId(0);

        await mainWindow.setAlwaysOnTop(true);
        await OpenFile.open(p.dirname(paths.first));
        await Future.delayed(Duration(milliseconds: 500));
        await WindowSetup.focusAndBringToFront(0);

        await WindowManagerPlus.current.invokeMethodToWindow(
            0, ProcessController.quickSuccess, results.length);
        await WindowManagerPlus.current.close();
        return;
      }
    }

    // For slow completion (or failure), show the window
    await WindowManagerPlus.current.waitUntilReadyToShow(WindowOptions(),
        () async {
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });

    // Focus just in case user got bored and clicked away
    await futures;
    await WindowManagerPlus.current.setAlwaysOnTop(true);
    await OpenFile.open(p.dirname(paths.first));
    await Future.delayed(Duration(milliseconds: 500));
    await WindowSetup.focusAndBringToFront();
  }

  static Future<String> _processFile(String? path) async {
    final inFile = File(path!);

    final pathWithoutExt = p.withoutExtension(path);
    final extension = p.extension(path);
    final outFilePath = "$pathWithoutExt-cleaned$extension";
    final outFile = File(outFilePath);

    if (!await inFile.exists()) {
      final filename = p.basename(path);
      return "Log \"$filename\" does not exist.";
    }
    if (await outFile.exists()) {
      final outFileName = p.basename(outFilePath);
      return "Log \"$outFileName\" already exists.";
    }

    final lines = await inFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where(FileFilter.onlyChat)
        .map(FileFilter.commonMap)
        .map(FileFilter.discordMap)
        .toList();

    await outFile.writeAsString(lines.join('\n'));

    return ProcessWindow.success;
  }
}

class ProcessBody extends StatelessWidget {
  const ProcessBody(
    this.futures,
    this.pathCount, {
    super.key,
  });

  final Future<List<String>> futures;
  final int pathCount;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: futures,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final successCount = snapshot.data!
            .where((result) => result == ProcessWindow.success)
            .length;
        final plural = pathCount == 1 ? "" : "s";

        if (successCount < pathCount) {
          final message = successCount == 0
              ? 'Log$plural failed to process:'
              : 'Log$plural processed with errors:';
          final color = successCount == 0
              ? Color.fromARGB(255, 211, 68, 68)
              : Colors.amber.shade300;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 6,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: color),
                  ),
                ),
                ErrorList(snapshot.data!),
                ProcessCloseButton(),
              ],
            ),
          );
        }

        // If all goes well
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Log$plural processed sucessfully!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(
                      height: 14,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: ProcessCloseButton(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProcessCloseButton extends StatelessWidget {
  const ProcessCloseButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
        ),
        onPressed: () async {
          await WindowManagerPlus.current.close();
        },
        child: Text('Close'),
      ),
    );
  }
}

class ErrorList extends StatefulWidget {
  const ErrorList(
    this.results, {
    super.key,
  });

  final List<String> results;

  @override
  State<ErrorList> createState() => _ErrorListState();
}

class _ErrorListState extends State<ErrorList> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final badResults = widget.results
        .where((result) => result != ProcessWindow.success)
        .toList(growable: false);

    return Expanded(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SmoothListView.builder(
          duration: Duration(milliseconds: 300),
          controller: _scrollController,
          itemCount: badResults.length,
          itemBuilder: (context, index) {
            final result = badResults[index];
            return Text(result);
          },
        ),
      ),
    );
  }
}
