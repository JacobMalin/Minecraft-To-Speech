import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import '../../setup/launcher.dart';
import '../../setup/path_formatting.dart';
import '../../setup/toaster.dart';
import '../../setup/window_setup.dart';
import '../../top_bar/top_bar.dart';
import 'instance_model.dart';

/// A dialog for adding a new instance.
class AddInstanceDialog extends StatefulWidget {
  /// A dialog for adding a new instance.
  const AddInstanceDialog({super.key});

  @override
  State<AddInstanceDialog> createState() => _AddInstanceDialogState();
}

class _AddInstanceDialogState extends State<AddInstanceDialog> {
  var _isChooseLauncher = true;
  Map<String, String> _paths = {};

  void _showOptions(Map<String, String> paths) {
    _paths = paths;

    setState(() {
      _isChooseLauncher = false;
    });
  }

  void _showLaunchers() {
    setState(() {
      _isChooseLauncher = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double horizPadding = 21, vertPadding = 13.5;

    return Dialog(
      insetPadding: const EdgeInsets.fromLTRB(
        horizPadding,
        vertPadding + MainTopBar.height,
        horizPadding,
        vertPadding,
      ),
      child: Stack(
        children: [
          if (_isChooseLauncher)
            _ChooseLauncher(_showOptions)
          else
            _ChoosePath(_paths),
          Positioned(
            left: 8,
            top: 8,
            child: SizedBox.square(
              dimension: 32,
              child: IconButton(
                iconSize: 22,
                padding: EdgeInsets.zero,
                icon: Icon(_isChooseLauncher ? Icons.close : Icons.arrow_back),
                onPressed: () {
                  if (_isChooseLauncher) {
                    Navigator.of(context).pop();
                  } else {
                    _showLaunchers();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChooseLauncher extends StatefulWidget {
  const _ChooseLauncher(
    Function(Map<String, String>) showOptions,
  ) : _showOptions = showOptions;

  final Function(Map<String, String>) _showOptions;

  @override
  State<_ChooseLauncher> createState() => _ChooseLauncherState();
}

class _ChooseLauncherState extends State<_ChooseLauncher> {
  final List<Widget> sources = [];

  final List<Launcher> _launchers = const [
    Minecraft(),
    CurseForge(),
    MultiMC(),
  ];

  @override
  void initState() {
    super.initState();

    for (final Launcher launcher in _launchers) {
      if (launcher.isValid) {
        sources.add(_AddFromLauncher(launcher, widget._showOptions));
      }
    }

    sources.add(const _AddFromLog());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, right: 26, bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Text(
                'Add Instance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final controller = ScrollController();
                  const double ignoreHeight = 52;
                  const double runSpacing = 12, spacing = 20;
                  const double heightBlock = 100 + runSpacing;
                  const double widthBlock = 100 + spacing;

                  final int numRows =
                      (constraints.maxHeight - ignoreHeight) ~/ heightBlock;
                  final int numCols = (sources.length / numRows).ceil();

                  return Scrollbar(
                    controller: controller,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: max(
                              numCols * widthBlock - spacing,
                              constraints.maxWidth,
                            ),
                          ),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: runSpacing,
                            children: sources,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChoosePath extends StatefulWidget {
  const _ChoosePath(
    Map<String, String> paths,
  ) : _paths = paths;

  final Map<String, String> _paths;

  @override
  State<_ChoosePath> createState() => _ChoosePathState();
}

class _ChoosePathState extends State<_ChoosePath> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const SizedBox(height: 14),
            Text(
              'Choose Instance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SmoothListView.builder(
                  shrinkWrap: true,
                  duration: const Duration(milliseconds: 300),
                  controller: _scrollController,
                  itemCount: widget._paths.length,
                  itemBuilder: (context, index) {
                    final String name = widget._paths.keys.elementAt(index);

                    final String instanceDirectory = p.dirname(
                      p.dirname(
                        widget._paths[name]!,
                      ),
                    );

                    return Material(
                      child: ListTile(
                        dense: true,
                        minVerticalPadding: 6,
                        minTileHeight: 0,
                        leading: const Icon(Icons.folder),
                        title: Text(
                          PathFormatting.breakBetter(name),
                        ),
                        subtitle: Text(
                          PathFormatting.breakBetter(instanceDirectory),
                          style: const TextStyle(fontSize: 10),
                        ),
                        onTap: () {
                          Provider.of<InstanceModel>(context, listen: false)
                              .addFromLog(widget._paths[name]!, name: name);

                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddFromLauncher extends StatelessWidget {
  const _AddFromLauncher(
    Launcher launcher,
    Function(Map<String, String>) showOptions,
  )   : _launcher = launcher,
        _showOptions = showOptions;

  final Launcher _launcher;
  final Function(Map<String, String>) _showOptions;

  @override
  Widget build(BuildContext context) {
    return _AddFromButton(
      icon: ImageIcon(
        _launcher.icon,
        size: 50,
      ),
      text: Text(
        _launcher.name,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () {
        final Map<String, String> paths = _launcher.getPaths();

        if (paths.isEmpty) {
          Toaster.showToast('No instances found.');
          return;
        } else if (paths.length == 1) {
          Provider.of<InstanceModel>(context, listen: false).addFromLog(
            paths[paths.keys.first]!,
            name: paths.keys.first,
          );

          Navigator.of(context).pop();
          return;
        }

        _showOptions(paths);
      },
    );
  }
}

class _AddFromLog extends StatefulWidget {
  const _AddFromLog();

  @override
  State<_AddFromLog> createState() => _AddFromLogState();
}

class _AddFromLogState extends State<_AddFromLog> {
  late final InstanceModel _instances;

  @override
  void initState() {
    super.initState();

    _instances = Provider.of<InstanceModel>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return _AddFromButton(
      icon: const Icon(Icons.add, size: 50),
      text: const Text(
        'Add from "latest.log"',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12),
      ),
      onPressed: () async {
        final String? path = await _pickLog();

        // If the user cancels the prompt, exit
        if (path == null) return;

        _instances.addFromLog(path);

        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
    );
  }

  Future<String?> _pickLog() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Minecraft Log File to Monitor',
      type: FileType.custom,
      allowedExtensions: ['log'],
    );

    unawaited(WindowSetup.focusAndBringToFront());

    if (result == null) return null; // If the user cancels the prompt, exit

    final String path = result.files.single.path!;

    if (p.basename(path) != 'latest.log') {
      Toaster.showToast('Please select a "latest.log" file.');
      return null;
    }

    return path;
  }
}

class _AddFromButton extends StatelessWidget {
  const _AddFromButton({
    required Widget icon,
    required Text text,
    required VoidCallback onPressed,
  })  : _icon = icon,
        _text = text,
        _onPressed = onPressed;

  final Widget _icon;
  final Text _text;
  final VoidCallback _onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: ElevatedButton(
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) {
                  return Theme.of(context).colorScheme.primaryContainer;
                },
              ),
              foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              iconColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            onPressed: _onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _icon,
                  _text,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
