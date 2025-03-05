import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:menu_bar/menu_bar.dart';
// I cannot find a better way to import this
// ignore: implementation_imports
import 'package:menu_bar/src/entry.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../main/instance/instance_model.dart';
import '../process/process_controller.dart';
import '../main/settings/settings_model.dart';

/// The Windows buttons in the top bar of the window. This includes the
/// minimize, maximize, and close buttons.
class WindowsButtons extends StatelessWidget {
  /// The Windows buttons in the top bar of the window. This includes the
  /// minimize, maximize, and close buttons.
  const WindowsButtons({
    required final Brightness? brightness,
    super.key,
  }) : _brightness = brightness;

  final Brightness? _brightness;

  @override
  Widget build(BuildContext context) {
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
          builder: (context, snapshot) {
            if (snapshot.data ?? false) {
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

/// The icon button in the top bar of the window. This button swaps between the
/// settings and home pages.
class IconSwapButton extends StatelessWidget {
  /// The icon button in the top bar of the window. This button swaps between
  /// the settings and home pages.
  const IconSwapButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color hoverColor = theme.colorScheme.onPrimary;
    final Color selectedColor = theme.colorScheme.onSecondary;

    Widget iconStyle(VoidCallback? onPressed, Icon icon) {
      return SizedBox(
        height: 33,
        width: 33,
        child: IconButton(
          padding: EdgeInsets.zero,
          hoverColor: hoverColor,
          highlightColor: selectedColor,
          onPressed: onPressed,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return theme.colorScheme.secondary;
              }
              return theme.colorScheme.onPrimaryContainer;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return theme.colorScheme.onSecondary;
              } else if (states.contains(WidgetState.hovered)) {
                return theme.colorScheme.onPrimary;
              }
              return Colors.transparent;
            }),
          ),
          icon: icon,
        ),
      );
    }

    final bool isSettings = Provider.of<SettingsModel>(context).isSettings;
    final SettingsModel settingsModel = Provider.of<SettingsModel>(context);

    final Widget settingsIcon = iconStyle(
      () => settingsModel.isSettings = true,
      const Icon(Icons.settings),
    );
    final Widget homeIcon = iconStyle(
      () => settingsModel.isSettings = false,
      const Icon(Icons.home),
    );

    return isSettings ? homeIcon : settingsIcon;
  }
}

/// The menu buttons in the top bar of the window. This includes the file and
/// process menus.
class MenuButtons extends StatelessWidget {
  /// The menu buttons in the top bar of the window. This includes the file and
  /// process menus.
  const MenuButtons({super.key});

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foregroundColor = theme.colorScheme.onPrimaryContainer;

    final bool isSettings = Provider.of<SettingsModel>(context).isSettings;
    final SettingsModel settingsModel =
        Provider.of<SettingsModel>(context, listen: false);

    const menuStyle = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      shadowColor: WidgetStatePropertyAll(Colors.transparent),
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(_height)),
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
    );
    final barButtonStyle = ButtonStyle(
      textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
      foregroundColor: WidgetStatePropertyAll(foregroundColor),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return theme.colorScheme.onSecondary;
        } else if (states.contains(WidgetState.hovered)) {
          return theme.colorScheme.onPrimary;
        }
        return Colors.transparent;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: const WidgetStatePropertyAll(Size(40, 20)),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.fromLTRB(10, 10, 10, 12)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ),
    );

    List<MenuEntry> instanceMenuItems(InstanceModel instances) => [
          MenuButton(
            text: const Text('Add Instance'),
            onTap: () async => instances.add(),
          ),
          MenuButton(
            text: const Text('Remove Instance'),
            onTap: () => instances.remove(),
          ),
          const MenuDivider(),
        ];
    final List<MenuEntry> alwaysMenuButtons = [
      MenuButton(
        text: const Text('Settings'),
        onTap: () => settingsModel.isSettings = true,
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

    return SizedBox(
      height: 32,
      child: IntrinsicWidth(
        child: Consumer<InstanceModel>(
          builder: (context, instances, child) {
            return MenuBarWidget(
              barStyle: menuStyle,
              barButtonStyle: barButtonStyle,
              barButtons: [
                BarButton(
                  text: const Text('File'),
                  submenu: SubMenu(
                    menuItems: isSettings
                        ? alwaysMenuButtons
                        : instanceMenuItems(instances) + alwaysMenuButtons,
                  ),
                ),
                BarButton(
                  text: const Text('Process'),
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
              child: const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
