import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../blacklist/blacklist.dart';
import '../main/instance/instance_model.dart';
import '../main/instance/log_filter.dart';
import '../main/settings/settings_box.dart';
import '../setup/focus_model.dart';
import '../setup/theme_setup.dart';
import '../setup/window_setup.dart';
import '../top_bar/top_bar.dart';
import 'process_controller.dart';

/// A window for processing Minecraft logs.
class ProcessApp extends StatefulWidget {
  /// A window for processing Minecraft logs.
  const ProcessApp(List<String> paths, {super.key}) : _paths = paths;

  final List<String> _paths;

  @override
  State<ProcessApp> createState() => _ProcessAppState();
}

class _ProcessAppState extends State<ProcessApp> {
  late final Future<List<String>> _futures;
  late final int _pathCount;

  @override
  void initState() {
    super.initState();

    _pathCount = widget._paths.length;
    unawaited(process(widget._paths));

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
        ChangeNotifierProvider<InstanceModel>(create: (_) => InstanceModel()),
        ChangeNotifierProvider<FocusModel>(create: (_) => FocusModel()),
      ],
      child: Selector<SettingsModel, ThemeMode>(
        selector: (_, settings) => settings.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Log Processing',
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: themeMode,
            builder: (context, child) => FocusWatcher(child!),
            home: Scaffold(
              appBar: const ProcessTopBar(),
              body: ProcessBody(_futures, _pathCount),
            ),
          );
        },
      ),
    );
  }

  Future<void> process(List<String> paths) async {
    var isCompleted = false;
    _futures = paths.map(_processLog).wait.whenComplete(() {
      isCompleted = true;
    });

    // Wait a bit before showing the window, to prevent immediate sucess from
    // opening a window
    await Future.delayed(const Duration(milliseconds: 400));

    // If process finished quickly, report back to the main window, unless there
    // was an error
    if (isCompleted) {
      final List<String> results = await _futures;

      final int sucessCount =
          results.where((result) => result == ProcessEvent.success).length;

      if (sucessCount == results.length) {
        final WindowManagerPlus mainWindow = WindowManagerPlus.fromWindowId(0);

        await mainWindow.setAlwaysOnTop(true);
        await OpenFile.open(p.dirname(paths.first));
        await Future.delayed(const Duration(milliseconds: 500));
        await WindowSetup.focusAndBringToFront(0);

        await WindowManagerPlus.current.invokeMethodToWindow(
          0,
          ProcessEvent.quickSuccess,
          results.length,
        );
        await WindowManagerPlus.current.close();
        return;
      }
    }

    // For slow completion (or failure), show the window
    await WindowManagerPlus.current.waitUntilReadyToShow(const WindowOptions(),
        () async {
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });

    // Focus just in case user got bored and clicked away
    await _futures;
    await WindowManagerPlus.current.setAlwaysOnTop(true);
    await OpenFile.open(p.dirname(paths.first));
    await Future.delayed(const Duration(milliseconds: 500));
    await WindowSetup.focusAndBringToFront();
  }

  static Future<String> _processLog(
    String? path,
  ) async {
    final inFile = File(path!);

    final String pathWithoutExt = p.withoutExtension(path);
    final String extension = p.extension(path);
    final outFilePath = '$pathWithoutExt-cleaned$extension';
    final outFile = File(outFilePath);

    if (!inFile.existsSync()) {
      final String filename = p.basename(path);
      return 'Log "$filename" does not exist.';
    }
    if (outFile.existsSync()) {
      final String outFileName = p.basename(outFilePath);
      return 'Log "$outFileName" already exists.';
    }

    final List<String> lines = await inFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where(LogFilter.onlyChat)
        .map(LogFilter.commonMap)
        .map(LogFilter.discordMap)
        .where(
          (msg) => Blacklist.filter(
            msg,
            blacklistStream: BlacklistStream.process,
          ),
        )
        .toList();

    await outFile.writeAsString(lines.join('\n'));

    return ProcessEvent.success;
  }
}

/// The main body of the process window.
class ProcessBody extends StatelessWidget {
  /// The main body of the process window.
  const ProcessBody(Future<List<String>> futures, int pathCount, {super.key})
      : _futures = futures,
        _pathCount = pathCount;

  final Future<List<String>> _futures;
  final int _pathCount;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _futures,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final int successCount = snapshot.data!
            .where((result) => result == ProcessEvent.success)
            .length;
        final plural = _pathCount == 1 ? '' : 's';

        if (successCount < _pathCount) {
          final message = successCount == 0
              ? 'Log$plural failed to process:'
              : 'Log$plural processed with errors:';
          final Color color = successCount == 0
              ? const Color.fromARGB(255, 211, 68, 68)
              : Colors.amber.shade300;

          return Padding(
            padding: const EdgeInsets.all(8),
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
                const ProcessCloseButton(),
              ],
            ),
          );
        }

        // If all goes well
        return Padding(
          padding: const EdgeInsets.all(8),
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
                    const SizedBox(
                      height: 14,
                    ),
                  ],
                ),
              ),
              const Positioned(
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

/// A close button for the process window.
class ProcessCloseButton extends StatelessWidget {
  /// A close button for the process window.
  const ProcessCloseButton({super.key});

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
        child: const Text('Close'),
      ),
    );
  }
}

/// A list of errors that occurred during processing.
class ErrorList extends StatefulWidget {
  /// A list of errors that occurred during processing.
  const ErrorList(
    List<String> results, {
    super.key,
  }) : _results = results;

  final List<String> _results;

  @override
  State<ErrorList> createState() => _ErrorListState();
}

class _ErrorListState extends State<ErrorList> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final List<String> badResults = widget._results
        .where((result) => result != ProcessEvent.success)
        .toList(growable: false);

    return Expanded(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SmoothListView.builder(
          duration: const Duration(milliseconds: 300),
          controller: _scrollController,
          itemCount: badResults.length,
          itemBuilder: (context, index) {
            final String result = badResults[index];
            return Text(result);
          },
        ),
      ),
    );
  }
}
