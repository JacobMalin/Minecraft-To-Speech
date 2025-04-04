import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../setup/path_formatting.dart';
import '../../setup/text_field_context.dart';
import '../../setup/theme_setup.dart';
import '../../top_bar/top_bar.dart';
import '../main_app.dart';
import 'chat_view.dart';
import 'instance_list.dart';
import 'instance_manager.dart';
import 'instance_model.dart';

/// Page for minecraft instances. This page is split into two parts: a list of
/// instances and a page showing the selected instance.
class InstancePage extends StatefulWidget {
  /// Constructor for the instance page.
  const InstancePage({super.key});

  @override
  State<InstancePage> createState() => _InstancePageState();
}

class _InstancePageState extends State<InstancePage> {
  @override
  Widget build(BuildContext context) {
    const double listMaxWidth = 320;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth * 0.3 < listMaxWidth) {
          return const Row(
            children: [
              Flexible(flex: 3, child: InstanceList()),
              Flexible(flex: 7, child: InstanceInfoPage()),
            ],
          );
        }

        return Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: listMaxWidth),
              child: const InstanceList(),
            ),
            const Expanded(child: InstanceInfoPage()),
          ],
        );
      },
    );
  }
}

/// Page for the selected instance. This page shows the instance name, path, and
/// buttons to enable/disable the instance, TTS, and Discord. It also shows the
/// chat messages from the instance.
class InstanceInfoPage extends StatefulWidget {
  /// Constructor for the instance info page.
  const InstanceInfoPage({super.key});

  @override
  State<InstanceInfoPage> createState() => _InstanceInfoPageState();
}

class _InstanceInfoPageState extends State<InstanceInfoPage> {
  late TextEditingController _controller;
  late int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    final InstanceModel instances =
        Provider.of<InstanceModel>(context, listen: false);
    _selectedIndex = instances.selectedIndex;
    _controller = TextEditingController(text: instances.selected?.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Maybe add open launcher button

    return Consumer<InstanceModel>(
      builder: (context, instances, child) {
        if (instances.selectedIndex == null) {
          _selectedIndex = null;
          return child!;
        }

        final InstanceController selected = instances.selected!;
        if (_selectedIndex != instances.selectedIndex) {
          _selectedIndex = instances.selectedIndex;
        }
        if (_controller.text != selected.name) _controller.text = selected.name;

        final double height =
            MainApp.minSize.height - MainTopBar.height - windowsTitleBarHeight;
        return Column(
          children: [
            Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10, width: double.infinity),
                  IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 180),
                      child: TextField(
                        controller: _controller,
                        contextMenuBuilder: TextFieldContext.builder,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                        onChanged: (newName) async =>
                            instances.updateWith(name: newName),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10, width: double.infinity),
                  Text(
                    PathFormatting.breakBetter(selected.instanceDirectory),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Expanded(
                    child: selected.isNotValid
                        ? const FileNotFoundButtons()
                        : InstanceInfoButtons(selected: selected),
                  ),
                ],
              ),
            ),
            const Expanded(child: ChatView()),
          ],
        );
      },
      child: Selector<InstanceModel, int>(
        selector: (context, instances) => instances.length,
        builder: (context, instancesLength, child) {
          // TODO: Maybe a home page
          // TODO: New user onboarding process / detection by checking if
          // instances hive file exists or if no instances

          return Center(
            child: instancesLength == 0
                ? const Text('Add an instance to get started!')
                : const Text('No instance selected.'),
          );
        },
      ),
    );
  }
}

/// Widget that is displayed when the instance log file is not found.
class FileNotFoundButtons extends StatelessWidget {
  /// Constructor for the file not found widget.
  const FileNotFoundButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final InstanceTheme instanceTheme =
        Theme.of(context).extension<InstanceTheme>()!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: instanceTheme.warning,
            ),
            Text(
              'Log file not found',
              style: TextStyle(color: instanceTheme.warning),
            ),
            Icon(
              Icons.warning_amber_rounded,
              color: instanceTheme.warning,
            ),
          ],
        ),
        Consumer<InstanceModel>(
          builder: (context, instances, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                // TODO: Make buttons less ugly
                ElevatedButton(
                  onPressed: () async => instances.locate(),
                  child: const Text('Locate'),
                ),
                ElevatedButton(
                  onPressed: () async => instances.remove(),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Buttons for the instance info page. These buttons allow the user to enable
/// or disable the instance, TTS, and Discord. The user can also open the
/// instance folder.
class InstanceInfoButtons extends StatelessWidget {
  /// Constructor for the instance info buttons.
  const InstanceInfoButtons({
    required InstanceController selected,
    super.key,
  }) : _selected = selected;

  final InstanceController _selected;

  @override
  Widget build(BuildContext context) {
    return Consumer<InstanceModel>(
      builder: (context, instances, child) {
        final InstanceTheme instanceTheme =
            Theme.of(context).extension<InstanceTheme>()!;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Switch(
              value: _selected.isEnabled,
              onChanged: (enabled) async => instances.updateWith(
                enabled: enabled,
              ),
              activeColor: instanceTheme.enabled,
              inactiveThumbColor: instanceTheme.disabled,
              inactiveTrackColor: instanceTheme.disabled.withAlpha(180),
              trackOutlineColor:
                  const WidgetStatePropertyAll(Colors.transparent),
              thumbIcon: WidgetStatePropertyAll(
                Icon(
                  Icons.power_settings_new,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            ToggleButtons(
              isSelected: [_selected.isTts, _selected.isDiscord],
              onPressed: _selected.isEnabled
                  ? (index) async {
                      switch (index) {
                        case 0:
                          await instances.updateWith(tts: !_selected.isTts);
                        case 1:
                          await instances.updateWith(
                            discord: !_selected.isDiscord,
                          );
                      }
                    }
                  : null,
              fillColor: instanceTheme.enabled.withAlpha(150),
              selectedColor: Theme.of(context).colorScheme.onSurface,
              borderWidth: 1,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('TTS'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Discord'),
                ),
              ],
            ),
            IconButton(
              onPressed: () async => instances.openInstanceFolder(),
              icon: const Icon(Icons.folder_open),
            ),
          ],
        );
      },
    );
  }
}
