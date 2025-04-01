import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../main/settings/settings_box.dart';
import '../setup/focus_model.dart';
import '../setup/theme_setup.dart';
import '../top_bar/top_bar.dart';
import 'blacklist_model.dart';

/// The main app for the blacklist window.
class BlacklistApp extends StatefulWidget {
  /// The main app for the blacklist window.
  const BlacklistApp({super.key});

  /// The minimum size of the window.
  static const minSize = Size(400, 300);

  @override
  State<BlacklistApp> createState() => _BlacklistAppState();
}

class _BlacklistAppState extends State<BlacklistApp> {
  @override
  void initState() {
    super.initState();

    BlacklistModel.cleanUp();

    const windowOptions = WindowOptions(
      title: 'Blacklist',
      size: Size(500, 400),
      minimumSize: BlacklistApp.minSize,
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    unawaited(
      WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
        await WindowManagerPlus.current.show();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BlacklistModel>(create: (_) => BlacklistModel()),
        ChangeNotifierProvider<SettingsModel>(create: (_) => SettingsModel()),
        ChangeNotifierProvider<FocusModel>(create: (_) => FocusModel()),
      ],
      child: Selector<SettingsModel, ThemeMode>(
        selector: (_, settings) => settings.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Blacklist',
            theme: ThemeSetup.brightTheme,
            darkTheme: ThemeSetup.darkTheme,
            themeMode: themeMode,
            builder: (context, child) => FocusWatcher(child!),
            home: const Scaffold(
              appBar: BlacklistTopBar(),
              body: BlacklistBody(),
            ),
          );
        },
      ),
    );
  }
}

/// The body of the blacklist window.
class BlacklistBody extends StatefulWidget {
  /// The body of the blacklist window.
  const BlacklistBody({
    super.key,
  });

  @override
  State<BlacklistBody> createState() => _BlacklistBodyState();
}

class _BlacklistBodyState extends State<BlacklistBody> {
  int? _selectedIndex;

  void _changeSelected(int? index) {
    BlacklistModel.deleteIfEmpty(_selectedIndex);

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _BlacklistList(_selectedIndex, _changeSelected)),
        const Divider(thickness: 2, height: 0),
        _BlacklistOptions(_selectedIndex, _changeSelected),
      ],
    );
  }
}

class _BlacklistOptions extends StatefulWidget {
  const _BlacklistOptions(
    int? selectedIndex,
    Function(int?) changeSelected,
  )   : _selectedIndex = selectedIndex,
        _changeSelected = changeSelected;

  final int? _selectedIndex;
  final Function(int?) _changeSelected;

  @override
  State<_BlacklistOptions> createState() => _BlacklistOptionsState();
}

class _BlacklistOptionsState extends State<_BlacklistOptions> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  int? _lastSelected;

  @override
  void initState() {
    super.initState();
    final BlacklistModel blacklist = Provider.of(context, listen: false);
    _controller = TextEditingController(
      text: widget._selectedIndex != null
          ? blacklist[widget._selectedIndex!].phrase
          : null,
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Consumer<BlacklistModel>(
        builder: (context, blacklist, child) {
          final BlacklistItem? selected = widget._selectedIndex != null &&
                  widget._selectedIndex! < blacklist.length
              ? blacklist[widget._selectedIndex!]
              : null;
          if (selected != null && _controller.text != selected.phrase) {
            _controller.text = selected.phrase;
          }

          if (_lastSelected != widget._selectedIndex) {
            _lastSelected = widget._selectedIndex;
            if (widget._selectedIndex == null) {
              _controller.text = '';
            }
          }

          return Column(
            spacing: 10,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          hintText: 'Enter phrase to blacklist',
                          hintStyle: TextStyle(
                            fontFamily: 'Minecraft', // Your Minecraft font
                            color: Colors.grey,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Minecraft', // Your Minecraft font
                          fontSize: 20,
                        ),
                        cursorHeight: 20,
                        onChanged: (value) {
                          if (widget._selectedIndex == null) {
                            blacklist.add(value);
                            widget._changeSelected(blacklist.length - 1);
                          } else {
                            blacklist.updateWith(
                              widget._selectedIndex!,
                              phrase: value,
                            );
                          }
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            blacklist.add('');
                            widget._changeSelected(blacklist.length - 1);
                          }
                          _focusNode.requestFocus();
                        },
                      ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: 36,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceBright,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        if (_controller.text.isNotEmpty ||
                            widget._selectedIndex == null) {
                          blacklist.add('');
                          widget._changeSelected(blacklist.length - 1);
                          _focusNode.requestFocus();
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ToggleButtons(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                    ),
                    isSelected: [
                      selected?.blacklistMatch == BlacklistMatch.exact,
                      selected?.blacklistMatch == BlacklistMatch.startsWith,
                      selected?.blacklistMatch == BlacklistMatch.endsWith,
                      selected?.blacklistMatch == BlacklistMatch.contains,
                    ],
                    onPressed: selected != null
                        ? (index) {
                            final BlacklistMatch match =
                                BlacklistMatch.values[index];

                            blacklist.updateWith(
                              widget._selectedIndex!,
                              blacklistMatch: match,
                            );
                          }
                        : null,
                    children: const [
                      Text('Exact'),
                      Text('Starts'),
                      Text('Ends'),
                      Text('Contains'),
                    ].map((text) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: text,
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (context) {
                      final Map<BlacklistStream, bool> isSelected = {
                        BlacklistStream.tts: selected?.blacklistStreams
                                .contains(BlacklistStream.tts) ??
                            false,
                        BlacklistStream.discord: selected?.blacklistStreams
                                .contains(BlacklistStream.discord) ??
                            false,
                        BlacklistStream.process: selected?.blacklistStreams
                                .contains(BlacklistStream.process) ??
                            false,
                      };

                      return ToggleButtons(
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          minWidth: 40,
                        ),
                        isSelected: [
                          isSelected[BlacklistStream.tts]!,
                          isSelected[BlacklistStream.discord]!,
                          isSelected[BlacklistStream.process]!,
                        ],
                        onPressed: selected != null
                            ? (index) {
                                final BlacklistStream stream =
                                    BlacklistStream.values[index];

                                final Set<BlacklistStream> streams =
                                    selected.blacklistStreams;
                                if (streams.contains(stream)) {
                                  streams.remove(stream);
                                } else {
                                  streams.add(stream);
                                }

                                blacklist.updateWith(
                                  widget._selectedIndex!,
                                  blacklistStreams: streams,
                                );
                              }
                            : null,
                        children: [
                          if (isSelected[BlacklistStream.tts]!)
                            BlacklistStream.tts.disabledIcon
                          else
                            BlacklistStream.tts.icon,
                          if (isSelected[BlacklistStream.discord]!)
                            BlacklistStream.discord.disabledIcon
                          else
                            BlacklistStream.discord.icon,
                          if (isSelected[BlacklistStream.process]!)
                            BlacklistStream.process.disabledIcon
                          else
                            BlacklistStream.process.icon,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BlacklistList extends StatelessWidget {
  const _BlacklistList(
    int? selectedIndex,
    Function(int?) changeSelected,
  )   : _selectedIndex = selectedIndex,
        _changeSelected = changeSelected;

  final int? _selectedIndex;
  final Function(int?) _changeSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<BlacklistModel>(
      builder: (context, blacklist, child) {
        if (blacklist.isEmpty) return child!;

        return SmoothListView.separated(
          key: const PageStorageKey('BlacklistListSmoothListView'),
          duration: const Duration(milliseconds: 400),
          physics: const ClampingScrollPhysics(),
          itemCount: blacklist.length,
          itemBuilder: (context, index) => _BlacklistItemTile(
            blacklist[index],
            index,
            selectedIndex: _selectedIndex,
            changeSelected: _changeSelected,
          ),
          separatorBuilder: (context, index) {
            if (index == _selectedIndex || index + 1 == _selectedIndex) {
              return const SizedBox.shrink();
            }

            return const Divider(
              thickness: 2,
              height: 0,
              indent: 10,
              endIndent: 10,
            );
          },
        );
      },
      child: const Center(
        child: Text('No items in blacklist!'),
      ),
    );
  }
}

/// A blacklist item tile.
class _BlacklistItemTile extends StatelessWidget {
  /// A blacklist item tile.
  const _BlacklistItemTile(
    BlacklistItem item,
    int index, {
    required Function(int?) changeSelected,
    required int? selectedIndex,
  })  : _item = item,
        _index = index,
        _selectedIndex = selectedIndex,
        _changeSelected = changeSelected;

  final BlacklistItem _item;
  final int _index;
  final int? _selectedIndex;
  final Function(int?) _changeSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<BlacklistModel>(
      builder: (context, blacklist, child) {
        return GestureDetector(
          onSecondaryTapDown: (details) async => showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy + 10,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            popUpAnimationStyle: AnimationStyle.noAnimation,
            constraints: const BoxConstraints(
              maxWidth: 220,
            ),
            items: [
              PopupMenuItem(
                onTap: () {
                  blacklist.delete(_index);

                  if (_selectedIndex != null) {
                    if (_selectedIndex == _index) {
                      _changeSelected(null);
                    } else if (_selectedIndex! > _index) {
                      _changeSelected(_selectedIndex! - 1);
                    }
                  }
                },
                child: const Text('Remove item'),
              ),
            ],
          ),
          child: _ChatMessage(
            item: _item,
            isSelected: _selectedIndex == _index,
            onTap: () =>
                _changeSelected(_selectedIndex == _index ? null : _index),
            trailing: _BlacklistIcons(_item),
          ),
        );
      },
    );
  }
}

class _BlacklistIcons extends StatelessWidget {
  const _BlacklistIcons(BlacklistItem item) : _item = item;

  final BlacklistItem _item;

  @override
  Widget build(BuildContext context) {
    final List<Widget> icons = [
      _blacklistIcon(BlacklistStream.tts),
      _blacklistIcon(BlacklistStream.discord),
      _blacklistIcon(BlacklistStream.process),
    ].whereType<Widget>().toList();

    return icons.isEmpty
        ? const Text(
            'Filter is disabled',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          )
        : Row(
            spacing: 2,
            children: icons,
          );
  }

  Widget? _blacklistIcon(BlacklistStream stream) {
    if (_item.blacklistStreams.contains(stream)) {
      return Builder(
        builder: (context) {
          return Consumer<BlacklistModel>(
            builder: (context, blacklist, child) {
              return Tooltip(
                preferBelow: false,
                verticalOffset: 10,
                message: 'Blacklisted from ${stream.name}',
                child: Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  child: stream.disabledIcon,
                ),
              );
            },
          );
        },
      );
    }
    return null;
  }
}

/// A singluar chat message styled to look like Minecraft chat.
class _ChatMessage extends StatelessWidget {
  /// Constructor for the chat message.
  const _ChatMessage({
    required BlacklistItem item,
    Widget? trailing,
    Color? tileColor,
    VoidCallback? onTap,
    bool? isSelected,
  })  : _item = item,
        _trailing = trailing,
        _tileColor = tileColor,
        _onTap = onTap,
        _isSelected = isSelected;

  final BlacklistItem _item;
  final Widget? _trailing;
  final Color? _tileColor;
  final VoidCallback? _onTap;
  final bool? _isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        minVerticalPadding: 0,
        minTileHeight: 0,
        tileColor: _tileColor ?? Theme.of(context).colorScheme.surfaceContainer,
        onTap: _onTap,
        selected: _isSelected ?? false,
        selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8, right: 4),
                child: Builder(
                  builder: (context) {
                    if (_item.phrase.isEmpty) {
                      return const Text(
                        'Empty filter',
                        textHeightBehavior: TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                        style: TextStyle(
                          fontFamily: 'Minecraft', // Your Minecraft font
                          fontSize: 20,
                          height: 1,
                          color: Colors.grey,
                        ),
                      );
                    }

                    return Text(
                      _message(),
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
                    );
                  },
                ),
              ),
            ),
            if (_trailing != null) _trailing,
          ],
        ),
      ),
    );
  }

  String _message() {
    switch (_item.blacklistMatch) {
      case BlacklistMatch.exact:
        return _item.phrase;
      case BlacklistMatch.startsWith:
        return '${_item.phrase}...';
      case BlacklistMatch.endsWith:
        return '...${_item.phrase}';
      case BlacklistMatch.contains:
        return '...${_item.phrase}...';
    }
  }
}
