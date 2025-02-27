import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../instance/instance_model.dart';
import '../instance/log_filter.dart';
import '../settings/settings_model.dart';
import '../setup/theme_setup.dart';
import '../setup/window_setup.dart';
import '../top_bar/top_bar.dart';
import 'process_controller.dart';

class ProcessWindow extends StatefulWidget {
  const ProcessWindow({
    super.key,
    required final Map<dynamic, dynamic> args,
  }) : _args = args;

  final Map _args;

  static const success = 'Success';

  @override
  State<ProcessWindow> createState() => _ProcessWindowState();
}

class _ProcessWindowState extends State<ProcessWindow> {
  late final Future<List<String>> _futures;
  late final int _pathCount;

  @override
  void initState() {
    super.initState();

    final List<String> paths = widget._args['paths'].cast<String>();
    _pathCount = paths.length;
    unawaited(process(paths));
  }

  @override
  Widget build(final BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>(
          create: (final _) => SettingsModel(),
        ),
        ChangeNotifierProvider<InstanceModel>(
          create: (final _) => InstanceModel(),
        ),
      ],
      child: Consumer<SettingsModel>(
        builder: (final context, final settings, final child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Log Processing',
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: settings.themeMode,
            home: Scaffold(
              appBar: const ProcessTopBar(),
              body: ProcessBody(_futures, _pathCount),
            ),
          );
        },
      ),
    );
  }

  Future<void> process(final List<String> paths) async {
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

      final int sucessCount = results
          .where((final result) => result == ProcessWindow.success)
          .length;

      if (sucessCount == results.length) {
        final WindowManagerPlus mainWindow = WindowManagerPlus.fromWindowId(0);

        await mainWindow.setAlwaysOnTop(true);
        await OpenFile.open(p.dirname(paths.first));
        await Future.delayed(const Duration(milliseconds: 500));
        await WindowSetup.focusAndBringToFront(0);

        await WindowManagerPlus.current.invokeMethodToWindow(
            0, ProcessController.quickSuccess, results.length);
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

  static Future<String> _processLog(final String? path) async {
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
        .toList();

    await outFile.writeAsString(lines.join('\n'));

    return ProcessWindow.success;
  }
}

class ProcessBody extends StatelessWidget {
  const ProcessBody(
    final Future<List<String>> futures,
    final int pathCount, {
    super.key,
  })  : _futures = futures,
        _pathCount = pathCount;

  final Future<List<String>> _futures;
  final int _pathCount;

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _futures,
      builder: (final context, final snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final int successCount = snapshot.data!
            .where((final result) => result == ProcessWindow.success)
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
                const ProcessCloseButton(),
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

class ProcessCloseButton extends StatelessWidget {
  const ProcessCloseButton({
    super.key,
  });

  @override
  Widget build(final BuildContext context) {
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

class ErrorList extends StatefulWidget {
  const ErrorList(
    final List<String> results, {
    super.key,
  }) : _results = results;

  final List<String> _results;

  @override
  State<ErrorList> createState() => _ErrorListState();
}

class _ErrorListState extends State<ErrorList> {
  final _scrollController = ScrollController();

  @override
  Widget build(final BuildContext context) {
    final List<String> badResults = widget._results
        .where((final result) => result != ProcessWindow.success)
        .toList(growable: false);

    return Expanded(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SmoothListView.builder(
          duration: const Duration(milliseconds: 300),
          controller: _scrollController,
          itemCount: badResults.length,
          itemBuilder: (final context, final index) {
            final String result = badResults[index];
            return Text(result);
          },
        ),
      ),
    );
  }
}
