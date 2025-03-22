import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main/settings/settings_box.dart';
import '../setup/toaster.dart';

/// This is a dialog that shows information about the application.
class AboutDialog extends StatefulWidget {
  /// This is a dialog that shows information about the application.
  const AboutDialog({super.key});

  @override
  State<AboutDialog> createState() => _AboutDialogState();
}

class _AboutDialogState extends State<AboutDialog> {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 12, 30, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'About Minecraft To Speech',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Selector<VelopackModel, String>(
              selector: (context, velopack) => velopack.currentVersion,
              builder: (context, version, child) {
                return Text(
                  'Version $version',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const _CheckForUpdates(),
            const SizedBox(height: 6),
            TextButton(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                  const EdgeInsets.fromLTRB(10, 11, 10, 13),
                ),
                minimumSize: WidgetStateProperty.all(Size.zero),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckForUpdates extends StatefulWidget {
  const _CheckForUpdates();

  @override
  State<_CheckForUpdates> createState() => _CheckForUpdatesState();
}

class _CheckForUpdatesState extends State<_CheckForUpdates> {
  final _controller = WidgetStatesController();
  var _isThinking = false;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return BorderSide(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
        } else if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(100),
          );
        }
        return BorderSide(color: Theme.of(context).colorScheme.outline);
      }),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
        const EdgeInsets.fromLTRB(10, 12, 10, 13),
      ),
      minimumSize: WidgetStateProperty.all(Size.zero),
      backgroundColor: WidgetStateProperty.all<Color>(
        Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      foregroundColor: WidgetStateProperty.all<Color>(
        Theme.of(context).colorScheme.onSurface,
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );

    return Column(
      spacing: 10,
      children: [
        _VersionInfo(isThinking: _isThinking),
        Consumer<VelopackModel>(
          builder: (context, velopack, child) {
            if (velopack.updateAvailable == UpdateResult.available) {
              return OutlinedButton(
                onPressed: () async {
                  final UpdateResult result = await velopack.updateAndRestart();
                  if (result == UpdateResult.success) {
                    // May be unreachable; Needs testing
                    Toaster.showToast('Updating! Application will restart.');
                  } else {
                    Toaster.showToast('Failed to update.');
                  }
                },
                style: buttonStyle,
                child: Text(
                  'Update to ${velopack.latestVersion}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }

            return OutlinedButton(
              onPressed: _isThinking
                  ? null
                  : () async {
                      setState(() {
                        _isThinking = true;
                      });
                      _controller.value.remove(WidgetState.hovered);

                      await [
                        // Give the user the impression that it is loading.
                        Future.delayed(const Duration(milliseconds: 500)),
                        velopack.checkForUpdates(),
                      ].wait;

                      if (mounted) {
                        setState(() {
                          _isThinking = false;
                        });
                      }
                    },
              style: buttonStyle,
              statesController: _controller,
              child: const Text(
                'Check for Updates',
                style: TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VersionInfo extends StatefulWidget {
  const _VersionInfo({
    required bool isThinking,
  }) : _isThinking = isThinking;

  final bool _isThinking;

  @override
  State<_VersionInfo> createState() => _VersionInfoState();
}

class _VersionInfoState extends State<_VersionInfo> {
  static const _style = TextStyle(fontSize: 12);

  late final StreamSubscription _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _ticker.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 100,
        minHeight: 40,
      ),
      child: IntrinsicWidth(
        child: Center(
          child: Builder(
            builder: (context) {
              if (widget._isThinking) {
                return const Row(
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Checking for updates...',
                      style: _style,
                    ),
                  ],
                );
              } else {
                return Consumer<VelopackModel>(
                  builder: (context, velopack, child) {
                    if (velopack.lastChecked == null) {
                      return const Text(
                        'Current version is unknown',
                        textAlign: TextAlign.center,
                        style: _style,
                      );
                    }

                    final Duration ago =
                        DateTime.now().difference(velopack.lastChecked!);

                    String result;
                    switch (velopack.updateAvailable) {
                      case UpdateResult.available:
                        result = 'An update is available';
                      case UpdateResult.outOfDate:
                        result = 'Was not able to check for updates';
                      case UpdateResult.debug:
                        result = 'Debug mode';
                      case null:
                      case UpdateResult.failed:
                        result = 'Failed to check for updates';
                      case UpdateResult.notAvailable:
                        result = 'You have the latest version';
                      case UpdateResult.success:
                        // Not possible
                        throw Exception('Unexpected update check result');
                    }

                    return Column(
                      children: [
                        Text(
                          result,
                          style: _style,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '(last checked ',
                              style: _style,
                            ),
                            Tooltip(
                              message: DateFormat("EEEE, MMMM d, y 'at' h:m a")
                                  .format(velopack.lastChecked!),
                              verticalOffset: 10,
                              preferBelow: false,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              textStyle: _style,
                              child: Text(
                                ago.agoFormat,
                                style: _style,
                              ),
                            ),
                            const Text(
                              ')',
                              style: _style,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// An extendsion that adds a method to display [Duration] in a short readable
/// format.
extension DurationAgo on Duration {
  /// Display the duration in a short readable format.
  String get agoFormat {
    if (inDays > 0) {
      return inDays == 1 ? '1 day ago' : '$inDays days ago';
    } else if (inHours > 0) {
      return inHours == 1 ? '1 hour ago' : '$inHours hours ago';
    } else if (inMinutes > 0) {
      return inMinutes == 1 ? '1 minute ago' : '$inMinutes minutes ago';
    } else {
      return 'just now';
    }
  }
}
