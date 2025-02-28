import 'package:dynamic_background/dynamic_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import '../settings/settings_model.dart';
import '../setup/theme_setup.dart';
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
    return const Row(
      children: [
        Flexible(
          flex: 3,
          child: InstanceList(),
        ),
        Flexible(
          flex: 7,
          child: InstanceInfoPage(),
        ),
      ],
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

        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 10,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        Flexible(
                          flex: 4,
                          child: TextField(
                            controller: _controller,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                            onChanged: (newName) =>
                                instances.updateWith(name: newName),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    Text(
                      // Makes spaces non-breaking and slashes breaking
                      selected.path
                          .replaceAll(' ', '\u202f')
                          .replaceAll(r'\', '\\\u200b'),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (selected.isNotValid)
                      const FileNotFoundButtons()
                    else
                      InstanceInfoButtons(selected: selected),
                  ],
                ),
              ),
              const Expanded(child: ChatView()),
            ],
          ),
        );
      },
      child: Consumer<InstanceModel>(
        builder: (context, instances, child) {
          // TODO: Maybe a home page

          return Center(
            child: instances.length == 0
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

    return Padding(
      padding: const EdgeInsets.all(6.5),
      child: Column(
        spacing: 10,
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
                spacing: 10,
                children: [
                  // TODO: Make buttons less ugly
                  ElevatedButton(
                    onPressed: () => instances.remove(),
                    child: const Text('Remove'),
                  ),
                  ElevatedButton(
                    onPressed: () async => instances.locate(),
                    child: const Text('Locate'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Consumer<InstanceModel>(
        builder: (context, instances, child) {
          final InstanceTheme instanceTheme =
              Theme.of(context).extension<InstanceTheme>()!;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Switch(
                value: _selected.isEnabled,
                onChanged: (enabled) => instances.updateWith(enabled: enabled),
                activeColor: instanceTheme.enabled,
                inactiveThumbColor: instanceTheme.disabled,
                inactiveTrackColor: instanceTheme.disabled.withAlpha(180),
                hoverColor: Colors.transparent,
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
                    ? (index) {
                        switch (index) {
                          case 0:
                            instances.updateWith(tts: !_selected.isTts);
                          case 1:
                            instances.updateWith(discord: !_selected.isDiscord);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                fillColor: instanceTheme.enabled.withAlpha(150),
                selectedColor: Theme.of(context).colorScheme.onSurface,
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
      ),
    );
  }
}

/// This shows the chat messages from the selected instance. Only chat messages
/// that are sent while the instance is enabled are shown.
class ChatView extends StatefulWidget {
  /// Constructor for the chat view.
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 41) return Container();

        return Consumer<InstanceModel>(
          builder: (context, instances, child) {
            final InstanceController? selected = instances.selected;
            if (selected == null) return child!;

            return SmoothListView.builder(
              key: PageStorageKey('ChatViewSmoothListView${selected.path}'),
              duration: const Duration(milliseconds: 400),
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              reverse: true,
              itemCount: selected.messages.length,
              itemBuilder: (context, index) => Material(
                child: ChatMessage(selected: selected, index: index),
              ),
            );
          },
          child: Container(),
        );
      },
    );
  }
}

/// A singluar chat message styled to look like Minecraft chat.
class ChatMessage extends StatelessWidget {
  /// Constructor for the chat message.
  const ChatMessage({
    required InstanceController selected,
    required int index,
    super.key,
  })  : _selected = selected,
        _index = index;

  final InstanceController _selected;
  final int _index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      minVerticalPadding: 0,
      minTileHeight: 0,
      tileColor: Theme.of(context).colorScheme.surfaceContainer,
      title: SelectableText(
        _selected.messages[_index],
        key: PageStorageKey(
          'ChatViewSmoothListViewSelectableText${_selected.path}$_index',
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: TextStyle(
          fontFamily: 'Minecraft', // Your Minecraft font
          fontSize: 20,
          height: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shadows: [
            Shadow(
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(70),
              offset: const Offset(2.49, 2.49),
            ),
          ],
        ),
      ),
    );
  }
}

/// List of instances. This list shows all instances and allows the user to add
/// and remove instances.
class InstanceList extends StatelessWidget {
  /// Constructor for the instance list.
  const InstanceList({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Consumer<InstanceModel>(
        builder: (context, instances, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SmoothListView.builder(
                key: const PageStorageKey('InstanceListSmoothListView'),
                duration: const Duration(milliseconds: 500),
                itemCount: instances.length + 1,
                itemBuilder: (context, index) {
                  if (index < instances.length) {
                    return InstanceTile(
                      index,
                      instances[index],
                      constraints.maxHeight,
                    );
                  }

                  return Consumer<SettingsModel>(
                    builder: (context, settings, child) {
                      return ListTile(
                        minTileHeight: 50,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        tileColor: settings.themeMode == ThemeMode.dark
                            ? Theme.of(context).colorScheme.surfaceContainerHigh
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        leading: const Icon(
                          Icons.add,
                          size: 24,
                        ),
                        title: Text(
                          'Add Instance',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTap: () async => instances.add(),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Tile for an instance. This tile shows the instance name and path. The tile
/// changes color based on the instance's status.
class InstanceTile extends StatelessWidget {
  /// Constructor for the instance tile.
  const InstanceTile(
    int index,
    InstanceController instance,
    double maxHeight, {
    super.key,
  })  : _index = index,
        _instance = instance,
        _maxHeight = maxHeight;

  final int _index;
  final InstanceController _instance;
  final double _maxHeight;

  @override
  Widget build(BuildContext context) {
    final InstanceTheme instanceTheme =
        Theme.of(context).extension<InstanceTheme>()!;

    return Consumer<InstanceModel>(
      builder: (context, instances, child) {
        final isSelected = instances.selectedIndex == _index;

        final Color selectedTileColor = Theme.of(context).colorScheme.secondary;

        Color tileColor, hoverColor, selectedColor, warningColor;
        if (_instance.isEnabled) {
          tileColor = instanceTheme.enabled;
          selectedColor = instanceTheme.enabled;
          hoverColor = instanceTheme.enabledHover;
          warningColor = instanceTheme.enabledWarning;
        } else {
          tileColor = instanceTheme.disabled;
          selectedColor = instanceTheme.disabled;
          hoverColor = instanceTheme.disabledHover;
          warningColor = instanceTheme.disableWarning;
        }

        if (_instance.isNotValid) {
          selectedColor = instanceTheme.warning;
        }

        return GestureDetector(
          onSecondaryTapDown: (details) async => _showRemoveContextMenu(
            context,
            details.globalPosition,
            removeInstance: () => instances.remove(_index),
          ),
          child: SingleChildBuilder(
            builder: (context, child) {
              if (_instance.isNotValid && !isSelected) {
                return DynamicBg(
                  height: 0,
                  painterData: ScrollerPainterData(
                    direction: ScrollDirection.left2Right,
                    shape: ScrollerShape.stripesDiagonalForward,
                    color: warningColor,
                    backgroundColor: tileColor,
                    fadeEdges: false,
                  ),
                  child: child,
                );
              } else {
                return child!;
              }
            },
            child: ListTile(
              minTileHeight: 0,
              contentPadding: const EdgeInsets.only(left: 10, right: 10),
              tileColor: tileColor,
              hoverColor: hoverColor,
              selectedTileColor: selectedTileColor,
              textColor: selectedTileColor,
              selectedColor: selectedColor,
              title: Text(
                _instance.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                // Makes colon and space non-breaking
                _instance.path
                    .replaceFirst(':', ':\u2060')
                    .replaceAll(' ', '\u202f'),
                maxLines: _maxHeight > 350 ? 3 : (_maxHeight > 250 ? 2 : 1),
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => instances.choose(_index),
              selected: isSelected,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRemoveContextMenu(
    BuildContext context,
    Offset position, {
    required VoidCallback removeInstance,
  }) async {
    const remove = 'remove';

    final String? result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      menuPadding: EdgeInsets.zero,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: [
        const PopupMenuItem(
          value: remove,
          height: 40,
          child: Text('Remove'),
        ),
      ],
    );

    if (result == remove) removeInstance();
  }
}
