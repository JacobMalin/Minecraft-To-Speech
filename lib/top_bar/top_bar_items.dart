import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:menu_bar/menu_bar.dart';
// I cannot find a better way to import this
// ignore: implementation_imports
import 'package:menu_bar/src/entry.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../instance/instance_model.dart';
import '../process/process_controller.dart';
import '../settings/settings_model.dart';

class WindowButtons extends StatelessWidget {
  const WindowButtons({
    super.key,
    required final Brightness? brightness,
  }) : _brightness = brightness;

  final Brightness? _brightness;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [
        WindowCaptionButton.minimize(
          brightness: _brightness,
          onPressed: () async {
            final bool isMinimized =
                await WindowManagerPlus.current.isMinimized();
            if (isMinimized) {
              await WindowManagerPlus.current.restore();
            } else {
              await WindowManagerPlus.current.minimize();
            }
          },
        ),
        FutureBuilder<bool>(
          // Both options are not valid
          // ignore: discarded_futures
          future: WindowManagerPlus.current.isMaximized(),
          builder: (final context, final snapshot) {
            if (snapshot.data == true) {
              return WindowCaptionButton.unmaximize(
                brightness: _brightness,
                onPressed: () async {
                  await WindowManagerPlus.current.unmaximize();
                },
              );
            }
            return WindowCaptionButton.maximize(
              brightness: _brightness,
              onPressed: () async {
                await WindowManagerPlus.current.maximize();
              },
            );
          },
        ),
        WindowCaptionButton.close(
          brightness: _brightness,
          onPressed: () async {
            await WindowManagerPlus.current.close();
          },
        ),
      ],
    );
  }
}

class IconSwapButton extends StatelessWidget {
  const IconSwapButton({
    super.key,
  });

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color hoverColor = theme.colorScheme.onPrimary;
    final Color selectedColor = theme.colorScheme.onSecondary;

    Widget iconStyle(final VoidCallback? onPressed, final Icon icon) {
      return SizedBox(
        height: 33,
        width: 33,
        child: IconButton(
          padding: const EdgeInsets.all(0),
          hoverColor: hoverColor,
          highlightColor: selectedColor,
          onPressed: onPressed,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((final states) {
              if (states.contains(WidgetState.pressed)) {
                return theme.colorScheme.secondary;
              }
              return theme.colorScheme.onPrimaryContainer;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((final states) {
              if (states.contains(WidgetState.pressed)) {
                return theme.colorScheme.onSecondary;
              } else if (states.contains(WidgetState.hovered)) {
                return theme.colorScheme.onPrimary;
              }
              return theme.colorScheme.primaryContainer;
            }),
          ),
          icon: icon,
        ),
      );
    }

    final bool isSettings = Provider.of<SettingsModel>(context).isSettings;
    final void Function({required bool isSettings}) changePage =
        Provider.of<SettingsModel>(context, listen: false).changePage;

    final Widget settingsIcon = iconStyle(
      () => changePage(isSettings: true),
      const Icon(Icons.settings),
    );
    final Widget homeIcon = iconStyle(
      () => changePage(isSettings: false),
      const Icon(Icons.home),
    );

    return isSettings ? homeIcon : settingsIcon;
  }
}

class MenuButtons extends StatelessWidget {
  const MenuButtons({
    super.key,
  });

  static const double height = 40;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color backgroundColor = theme.colorScheme.primaryContainer;
    final Color foregroundColor = theme.colorScheme.onPrimaryContainer;

    final bool isSettings = Provider.of<SettingsModel>(context).isSettings;
    final void Function({required bool isSettings}) changePage =
        Provider.of<SettingsModel>(context, listen: false).changePage;

    final menuStyle = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.only(top: 15, bottom: 15),
      ),
    );
    final barButtonStyle = ButtonStyle(
      textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
      foregroundColor: WidgetStatePropertyAll(foregroundColor),
      backgroundColor: WidgetStateProperty.resolveWith((final states) {
        if (states.contains(WidgetState.pressed)) {
          return theme.colorScheme.onSecondary;
        } else if (states.contains(WidgetState.hovered)) {
          return theme.colorScheme.onPrimary;
        }
        return theme.colorScheme.primaryContainer;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: const WidgetStatePropertyAll(Size(40, 20)),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.fromLTRB(10, 10, 10, 12)),
      alignment: Alignment.center,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ),
    );

    List<MenuEntry> instanceMenuItems(final instances) => [
          MenuButton(
            text: const Text('Add Instance'),
            onTap: () => instances.add(),
          ),
          MenuButton(
            text: const Text('Remove Instance'),
            onTap: () => instances.remove(),
          ),
          const MenuDivider()
        ];
    final List<MenuEntry> alwaysMenuButtons = [
      MenuButton(
        text: const Text('Settings'),
        onTap: () => changePage(isSettings: true),
        icon: const Icon(Icons.settings),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyO, control: true),
        shortcutText: 'Ctrl+O',
      ),
      const MenuDivider(),
      MenuButton(
        text: const Text('Exit'),
        onTap: () async => WindowManagerPlus.current.close(),
        icon: const Icon(Icons.exit_to_app),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
        shortcutText: 'Ctrl+Q',
      ),
    ];

    return Consumer<InstanceModel>(
        builder: (final context, final instances, final child) {
      return MenuBarWidget(
        barStyle: menuStyle,
        barButtonStyle: barButtonStyle,
        barButtons: [
          BarButton(
            text: const Center(child: Text('File')),
            submenu: SubMenu(
              menuItems: isSettings
                  ? alwaysMenuButtons
                  : instanceMenuItems(instances) + alwaysMenuButtons,
            ),
          ),
          BarButton(
            text: const Center(child: Text('Process')),
            submenu: SubMenu(
              menuItems: [
                MenuButton(
                  text: const Text('Process Log'),
                  onTap: () async => ProcessController.process(),
                ),
              ],
            ),
          ),
        ],
        child: Container(),
      );
    });
  }
}
