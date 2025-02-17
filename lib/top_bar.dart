import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:provider/provider.dart';

import 'file/file_model.dart';
import 'settings/settings_model.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({
    super.key,
  });

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: WindowTitleBarBox(
        child: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              MoveWindow(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
                  child: ImageIcon(AssetImage("assets/mts_icon.ico")),
                ),
              ),
              IntrinsicWidth(
                child: MenuButtons(),
              ),
              Expanded(
                child: MoveWindow(),
              ),
              IconSwapButton(),
              WindowButtons(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(height);
}

class IconSwapButton extends StatelessWidget {
  const IconSwapButton({
    super.key,
  });

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
          padding: EdgeInsets.all(0),
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
              return theme.colorScheme.primaryContainer;
            }),
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
            animationDuration: Duration.zero,
            splashFactory: NoSplash.splashFactory,
          ),
          icon: icon,
        ),
      );
    }

    final isSettings = Provider.of<SettingsModel>(context).isSettings;
    final changePage = Provider.of<SettingsModel>(context, listen: false).changePage;

    final settingsIcon = iconStyle(
      () => changePage(true),
      Icon(Icons.settings),
    );
    final homeIcon = iconStyle(
      () => changePage(false),
      Icon(Icons.home),
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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color backgroundColor = theme.colorScheme.primaryContainer;
    final Color foregroundColor = theme.colorScheme.onPrimaryContainer;

    final isSettings = Provider.of<SettingsModel>(context).isSettings;
    final changePage = Provider.of<SettingsModel>(context, listen: false).changePage;

    final menuStyle = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      shadowColor: WidgetStatePropertyAll(Colors.transparent),
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(height)),
      padding: WidgetStatePropertyAll(
        const EdgeInsets.only(top: 15, bottom: 15),
      ),
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
        return theme.colorScheme.primaryContainer;
      }),
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
      minimumSize: WidgetStatePropertyAll(Size(40, 20)),
      padding:
          WidgetStatePropertyAll(const EdgeInsets.fromLTRB(10, 10, 10, 12)),
      animationDuration: Duration.zero,
      alignment: Alignment.center,
      splashFactory: NoSplash.splashFactory,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ),
    );
    final menuButtonStyle = ButtonStyle(
      splashFactory: NoSplash.splashFactory,
    );

    fileMenuItems(files) => [
          MenuButton(
            text: const Text('Add File'),
            onTap: () => files.add(),
            // icon: const Icon(Icons.file_open_outlined),
            // shortcutText: 'Ctrl+O',
          ),
          MenuButton(
            text: const Text('Remove File'),
            onTap: () => files.remove(),
            // shortcut: SingleActivator(LogicalKeyboardKey.backspace),
            // shortcutText: 'Backspace',
          ),
          const MenuDivider()
        ];
    final alwaysMenuButtons = [
      MenuButton(
        text: const Text('Settings'),
        onTap: () => changePage(true),
        icon: const Icon(Icons.settings),
        shortcut: SingleActivator(LogicalKeyboardKey.keyO, control: true),
        shortcutText: 'Ctrl+O',
      ),
      const MenuDivider(),
      MenuButton(
        text: const Text('Exit'),
        onTap: () => appWindow.close(),
        icon: const Icon(Icons.exit_to_app),
        shortcut: SingleActivator(LogicalKeyboardKey.keyQ, control: true),
        shortcutText: 'Ctrl+Q',
      ),
    ];

    return Consumer<FileModel>(builder: (context, files, child) {
      return MenuBarWidget(
        barStyle: menuStyle,
        barButtonStyle: barButtonStyle,
        menuButtonStyle: menuButtonStyle,
        barButtons: [
          BarButton(
            text: Center(child: const Text('File')),
            submenu: SubMenu(
              menuItems: (isSettings ? alwaysMenuButtons : fileMenuItems(files) + alwaysMenuButtons),
            ),
          ),
        ],
        child: Container(),
      );
    });
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foregroundColor = theme.colorScheme.onPrimaryContainer;

    final colors = WindowButtonColors(
      iconNormal: foregroundColor,
      iconMouseOver: theme.colorScheme.primary,
      iconMouseDown: theme.colorScheme.secondary,
      mouseOver: theme.colorScheme.onPrimary,
      mouseDown: theme.colorScheme.onSecondary,
    );
    final closeColors = WindowButtonColors(
      iconNormal: foregroundColor,
      mouseOver: Color(0xFFD32F2F),
      mouseDown: Color(0xFFB71C1C),
      iconMouseOver: Color(0xFFFFFFFF),
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: colors),
        MaximizeWindowButton(colors: colors),
        CloseWindowButton(colors: closeColors),
      ],
    );
  }
}
