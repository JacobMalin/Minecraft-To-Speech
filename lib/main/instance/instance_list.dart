import 'package:dynamic_background/dynamic_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import '../../setup/path_formatting.dart';
import '../../setup/theme_setup.dart';
import '../settings/settings_box.dart';
import 'instance_manager.dart';
import 'instance_model.dart';

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
              return SmoothListView.separated(
                key: const PageStorageKey('InstanceListSmoothListView'),
                duration: const Duration(milliseconds: 500),
                separatorBuilder: (context, index) {
                  if (index >= instances.length - 1) {
                    return const SizedBox.shrink();
                  }

                  final enabledDifferent = instances[index].isEnabled !=
                      instances[index + 1].isEnabled;
                  final validDifferent = instances[index].isNotValid !=
                      instances[index + 1].isNotValid;
                  final bool thisOrNextSelected =
                      instances.selectedIndex == index ||
                          instances.selectedIndex == index + 1;
                  if (enabledDifferent ||
                      validDifferent ||
                      thisOrNextSelected) {
                    return const SizedBox.shrink();
                  }

                  return Divider(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withAlpha(80),
                    height: 0,
                    indent: 20,
                    endIndent: 20,
                  );
                },
                itemCount: instances.length + 1,
                itemBuilder: (context, index) {
                  if (index < instances.length) {
                    return _InstanceTile(
                      index,
                      instances[index],
                      constraints.maxHeight,
                    );
                  }

                  return const _AddFileButton();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AddFileButton extends StatelessWidget {
  const _AddFileButton();

  @override
  Widget build(BuildContext context) {
    return Selector<InstanceModel, Future<void> Function()>(
      selector: (context, instances) => instances.add,
      builder: (context, addInstance, child) {
        return Selector<SettingsModel, ThemeMode>(
          selector: (context, settings) => settings.themeMode,
          builder: (context, themeMode, child) {
            return ListTile(
              horizontalTitleGap: 8,
              minTileHeight: 50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 7),
              tileColor: themeMode == ThemeMode.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              leading: Icon(
                Icons.add,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                'Add Instance',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              onTap: () async => addInstance(),
            );
          },
        );
      },
    );
  }
}

/// Tile for an instance. This tile shows the instance name and path. The tile
/// changes color based on the instance's status.
class _InstanceTile extends StatelessWidget {
  /// Constructor for the instance tile.
  const _InstanceTile(
    int index,
    InstanceController instance,
    double maxHeight,
  )   : _index = index,
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
          onSecondaryTapDown: (details) async => _showInstanceContextMenu(
            context,
            details.globalPosition,
            _index,
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
                PathFormatting.breakLess(_instance.instanceDirectory),
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

  Future<void> _showInstanceContextMenu(
    BuildContext context,
    Offset position,
    int index,
  ) async {
    final InstanceModel instances =
        Provider.of<InstanceModel>(context, listen: false);

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      menuPadding: EdgeInsets.zero,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: <PopupMenuEntry<void>>[
        if (index > 0)
          PopupMenuItem(
            height: 40,
            onTap: () => instances.moveUp(index),
            child: const Text('Move Up'),
          ),
        if (index < instances.length - 1)
          PopupMenuItem(
            height: 40,
            onTap: () => instances.moveDown(index),
            child: const Text('Move Down'),
          ),
        if (index > 0 || index < instances.length - 1) const PopupMenuDivider(),
        PopupMenuItem(
          height: 40,
          onTap: () => instances.remove(index),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}
