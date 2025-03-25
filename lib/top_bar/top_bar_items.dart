import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter/services.dart';
import 'package:menu_bar/menu_bar.dart';
// I cannot find a better way to import this
// ignore: implementation_imports
import 'package:menu_bar/src/entry.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../main/instance/instance_model.dart';
import '../main/settings/settings_box.dart';
import '../process/process_controller.dart';
import '../setup/dialog_service.dart';
import '../setup/toaster.dart';
import 'about_dialog.dart';
import 'top_bar.dart';

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

/// The update available button in the top bar of the window. This button opens
/// the the about menu.
class UpdateAvailableButton extends StatelessWidget {
  /// The update available button in the top bar of the window. This button
  /// opens the the about menu.
  const UpdateAvailableButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color hoverColor = theme.colorScheme.onPrimary;
    final Color selectedColor = theme.colorScheme.onSecondary;

    return SizedBox(
      height: 33,
      width: 33,
      child: IconButton(
        padding: EdgeInsets.zero,
        hoverColor: hoverColor,
        highlightColor: selectedColor,
        onPressed: () async {
          await DialogService.showDialogElsewhere(
            builder: (_) => const UpdateAvailableDialog(),
          );
        },
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
        icon: const Icon(Icons.update),
      ),
    );
  }
}

/// The update available dialog that opens when an update is available.
class UpdateAvailableDialog extends StatefulWidget {
  /// The update available dialog that opens when an update is available.
  const UpdateAvailableDialog({super.key});

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  var _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.only(top: MainTopBar.height),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Consumer<SettingsModel>(
          builder: (context, settings, child) {
            return IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'An update is available!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text('Would you like to update now?'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: Builder(
                      builder: (context) {
                        if (_isUpdating) {
                          return const Center(
                            child: SizedBox.square(
                              dimension: 40,
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            CheckboxTile(
                              text: 'Do not notify me of updates',
                              value: settings.hideUpdate,
                              onChanged: () =>
                                  settings.hideUpdate = !settings.hideUpdate,
                            ),
                            CheckboxTile(
                              text: 'Automatically update when available',
                              value: settings.autoUpdate,
                              onChanged: () =>
                                  settings.autoUpdate = !settings.autoUpdate,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<VelopackModel>(
                        builder: (context, velopack, child) {
                          return TextButton(
                            onPressed: () async {
                              if (mounted) {
                                setState(() {
                                  _isUpdating = true;
                                });
                              }

                              final (UpdateResult result, _) = await (
                                velopack.updateAndRestart(),
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                )
                              ).wait;

                              if (result != UpdateResult.success) {
                                Toaster.showToast('Failed to update.');
                              }

                              if (mounted) {
                                setState(() {
                                  _isUpdating = false;
                                });
                              }
                            },
                            child: const Text('Update'),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: settings.autoUpdate
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('No'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A tile with a checkbox and text. A better version of CheckboxListTile.
class CheckboxTile extends StatelessWidget {
  /// A tile with a checkbox and text. A better version of CheckboxListTile.
  const CheckboxTile({
    required String text,
    required bool value,
    required VoidCallback onChanged,
    super.key,
  })  : _text = text,
        _value = value,
        _onChanged = onChanged;

  final String _text;
  final bool _value;
  final VoidCallback _onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            value: _value,
            onChanged: (_) => _onChanged(),
          ),
        ),
        TextButton(
          style: ButtonStyle(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.bodySmall,
            ),
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onSurface,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 2),
            ),
          ),
          onPressed: _onChanged,
          child: Text(_text),
        ),
      ],
    );
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
            onTap: () async => instances.remove(),
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
                BarButton(
                  text: const Text('Help'),
                  submenu: SubMenu(
                    menuItems: [
                      MenuButton(
                        text: const Text('About'),
                        onTap: () async => DialogService.showDialogElsewhere(
                          builder: (_) => const AboutDialog(),
                        ),
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
