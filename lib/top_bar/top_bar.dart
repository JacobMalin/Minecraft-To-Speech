import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../settings/settings_model.dart';
import 'top_bar_items.dart';

/// The top bar of the main window.
class MainTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The top bar of the main window.
  const MainTopBar({super.key});

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return _TopBar(
      height: _height,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      icon: const Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 6, 0),
        child: ImageIcon(AssetImage('assets/mts_icon.ico')),
      ),
      menuButtons: const IntrinsicWidth(child: MenuButtons()),
      nextToWindowButtons: const IconSwapButton(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_height);
}

/// The top bar of the process window.
class ProcessTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The top bar of the process window.
  const ProcessTopBar({super.key});

  static const double _height = 30;

  @override
  Widget build(BuildContext context) {
    return _TopBar(
      height: _height,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.onSecondary
          : Theme.of(context).colorScheme.secondaryFixed,
      icon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ImageIcon(
          size: 20,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          const AssetImage('assets/mts_icon.ico'),
        ),
      ),
      title: Text(
        'Log Processing',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_height);
}

class _TopBar extends StatefulWidget {
  const _TopBar({
    required double height,
    required Color backgroundColor,
    this.icon = const SizedBox(),
    this.title = const SizedBox(),
    this.menuButtons = const SizedBox(),
    this.nextToWindowButtons = const SizedBox(),
  })  : _backgroundColor = backgroundColor,
        _height = height;

  final double _height;
  final Color _backgroundColor;

  final Widget icon;
  final Widget title;
  final Widget menuButtons;
  final Widget nextToWindowButtons;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> with WindowListener {
  @override
  void initState() {
    WindowManagerPlus.current.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        final Brightness brightness = settings.themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;

        return DecoratedBox(
          decoration: BoxDecoration(color: widget._backgroundColor),
          child: SizedBox(
            height: widget._height,
            child: Row(
              children: [
                DragToMoveArea(
                  child: Row(
                    children: [
                      widget.icon,
                      widget.title,
                    ],
                  ),
                ),
                widget.menuButtons,
                const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
                widget.nextToWindowButtons,
                WindowsButtons(brightness: brightness),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void onWindowMaximize([int? windowId]) {
    setState(() {});
  }

  @override
  void onWindowUnmaximize([int? windowId]) {
    setState(() {});
  }

  @override
  void onWindowFocus([int? windowId]) {
    // Make sure to call once.
    setState(() {});
  }
}
