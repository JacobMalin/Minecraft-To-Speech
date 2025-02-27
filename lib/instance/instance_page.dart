import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import '../settings/settings_model.dart';
import '../setup/theme_setup.dart';
import 'instance_manager.dart';
import 'instance_model.dart';

class InstancePage extends StatefulWidget {
  const InstancePage({
    super.key,
  });

  @override
  State<InstancePage> createState() => _InstancePageState();
}

class _InstancePageState extends State<InstancePage> {
  @override
  Widget build(final BuildContext context) {
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

class InstanceInfoPage extends StatefulWidget {
  const InstanceInfoPage({
    super.key,
  });

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
  Widget build(final BuildContext context) {
    return Consumer<InstanceModel>(
      builder: (final context, final instances, final child) {
        if (instances.selectedIndex == null) {
          _selectedIndex = null;
          return child!;
        }

        final InstanceController selected = instances.selected!;
        if (_selectedIndex != instances.selectedIndex) {
          _selectedIndex = instances.selectedIndex;
        }
        if (_controller.text != selected.name) _controller.text = selected.name;

        final InstanceTheme instanceTheme =
            Theme.of(context).extension<InstanceTheme>()!;

        if (selected.isNotValid) {
          return const FileNotFound();
        }

        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
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
                            onChanged: (final newName) =>
                                instances.updateWith(name: newName),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      // Makes spaces non-breaking and slashes breaking
                      selected.path
                          .replaceAll(' ', '\u202f')
                          .replaceAll('\\', '\\\u200b'),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 25),
                    InstanceInfoButtons(
                      selected: selected,
                      instanceTheme: instanceTheme,
                    ),
                  ],
                ),
              ),
              const Expanded(child: ChatView()),
            ],
          ),
        );
      },
      child: Consumer<InstanceModel>(
          builder: (final context, final instances, final child) {
        // TODO: Maybe a home page

        return Center(
          child: instances.length == 0
              ? const Text('Add an instance to get started!')
              : const Text('No instance selected.'),
        );
      }),
    );
  }
}

class FileNotFound extends StatelessWidget {
  const FileNotFound({
    super.key,
  });

  // TODO: Implement

  @override
  Widget build(final BuildContext context) {
    return const Placeholder();
  }
}

class InstanceInfoButtons extends StatelessWidget {
  const InstanceInfoButtons({
    super.key,
    required final InstanceController selected,
    required final InstanceTheme instanceTheme,
  })  : _instanceTheme = instanceTheme,
        _selected = selected;

  final InstanceController _selected;
  final InstanceTheme _instanceTheme;

  @override
  Widget build(final BuildContext context) {
    return Consumer<InstanceModel>(
        builder: (final context, final instances, final child) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          Switch(
            value: _selected.isEnabled,
            onChanged: (final enabled) =>
                instances.updateWith(enabled: enabled),
            activeColor: _instanceTheme.green,
            inactiveThumbColor: _instanceTheme.red,
            inactiveTrackColor: _instanceTheme.red.withAlpha(180),
            hoverColor: Colors.transparent,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
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
                ? (final index) {
                    switch (index) {
                      case 0:
                        instances.updateWith(tts: !_selected.isTts);
                      case 1:
                        instances.updateWith(discord: !_selected.isDiscord);
                    }
                  }
                : null,
            borderRadius: BorderRadius.circular(10),
            fillColor: _instanceTheme.green.withAlpha(150),
            selectedColor: Theme.of(context).colorScheme.onSurface,
            splashColor: Colors.transparent,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text('TTS'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text('Discord'),
              ),
            ],
          ),
          IconButton(
            onPressed: () async => instances.openSecondFolder(),
            icon: const Icon(Icons.folder_open),
            splashColor: Colors.transparent,
          ),
        ],
      );
    });
  }
}

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(builder: (final context, final constraints) {
      if (constraints.maxHeight < 41) return Container();

      return Consumer<InstanceModel>(
        builder: (final context, final instances, final child) {
          final InstanceController? selected = instances.selected;
          if (selected == null) return child!;

          return SmoothListView.builder(
            key: PageStorageKey('ChatViewSmoothListView${selected.path}'),
            duration: const Duration(milliseconds: 400),
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20),
            reverse: true,
            itemCount: selected.messages.length,
            itemBuilder: (final context, final index) => Material(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                minVerticalPadding: 0,
                minTileHeight: 0,
                tileColor: Theme.of(context).colorScheme.surfaceContainer,
                title: SelectableText(
                  selected.messages[index],
                  key: PageStorageKey(
                    'ChatViewSmoothListViewSelectableText${selected.path}$index',
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withAlpha(70),
                        offset: const Offset(2.49, 2.49),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: Container(),
      );
    });
  }
}

class InstanceList extends StatelessWidget {
  const InstanceList({
    super.key,
  });

  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Consumer<InstanceModel>(
        builder: (final context, final instances, final child) {
          return LayoutBuilder(builder: (final context, final constraints) {
            return SmoothListView.builder(
              key: const PageStorageKey('InstanceListSmoothListView'),
              duration: const Duration(milliseconds: 500),
              itemCount: instances.length + 1,
              itemBuilder: (final context, final index) {
                if (index < instances.length) {
                  return InstanceTile(
                    index,
                    instances[index],
                    constraints.maxHeight,
                  );
                }

                return Consumer<SettingsModel>(
                    builder: (final context, final settings, final child) {
                  return ListTile(
                    minTileHeight: 50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    tileColor: settings.themeMode == ThemeMode.dark
                        ? Theme.of(context).colorScheme.surfaceContainerHigh
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                });
              },
            );
          });
        },
      ),
    );
  }
}

class InstanceTile extends StatelessWidget {
  const InstanceTile(
    final int index,
    final InstanceController instance,
    final double maxHeight, {
    super.key,
  })  : _index = index,
        _instance = instance,
        _maxHeight = maxHeight;

  final int _index;
  final InstanceController _instance;
  final double _maxHeight;

  // TODO: Change color on instance log file missing

  @override
  Widget build(final BuildContext context) {
    final InstanceTheme instanceTheme =
        Theme.of(context).extension<InstanceTheme>()!;

    return Consumer<InstanceModel>(
      builder: (final context, final instances, final child) {
        final bool selected = instances.selectedIndex == _index;

        return GestureDetector(
          onSecondaryTapDown: (final details) async => _showRemoveContextMenu(
            context,
            details.globalPosition,
            removeInstance: () => instances.remove(_index),
          ),
          child: ListTile(
            minTileHeight: 0,
            contentPadding: const EdgeInsets.only(left: 10, right: 10),
            tileColor:
                _instance.isEnabled ? instanceTheme.green : instanceTheme.red,
            hoverColor: _instance.isEnabled
                ? instanceTheme.greenHover
                : instanceTheme.redHover,
            selectedTileColor: Theme.of(context).colorScheme.secondary,
            splashColor: Colors.transparent,
            textColor: Theme.of(context).colorScheme.secondary,
            selectedColor:
                _instance.isEnabled ? instanceTheme.green : instanceTheme.red,
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
            selected: selected,
          ),
        );
      },
    );
  }

  Future<void> _showRemoveContextMenu(
    final BuildContext context,
    final Offset position, {
    required final Function removeInstance,
  }) async {
    const remove = 'remove';

    final String? result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      menuPadding: const EdgeInsets.all(0),
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
