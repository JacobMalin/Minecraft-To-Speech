import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import '../../blacklist/blacklist_model.dart';
import '../../setup/toaster.dart';
import 'instance_manager.dart';
import 'instance_model.dart';

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
    return Consumer<InstanceModel>(
      builder: (context, instances, child) {
        final InstanceController? selected = instances.selected;

        if (selected == null || selected.messages.isEmpty) return child!;

        return SmoothListView.builder(
          key: PageStorageKey('ChatViewSmoothListView${selected.path}'),
          duration: const Duration(milliseconds: 400),
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20),
          reverse: true,
          itemCount: selected.messages.length,
          itemBuilder: (context, index) =>
              _InstanceChatMessage(selected.messages[index]),
        );
      },
      child: Container(),
    );
  }
}

class _BlacklistIcons extends StatelessWidget {
  const _BlacklistIcons(String message) : _message = message;

  final String _message;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 2,
      children: [
        _blacklistIcon(BlacklistStream.tts),
        _blacklistIcon(BlacklistStream.discord),
        _blacklistIcon(BlacklistStream.process),
      ].whereType<Widget>().toList(),
    );
  }

  Widget? _blacklistIcon(BlacklistStream stream) {
    if (!BlacklistModel.filter(_message, blacklistStream: stream)) {
      return Builder(
        builder: (context) {
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
                      onTap: () => blacklist.modifyToAllow(_message, stream),
                      child: Text(
                        'Modify blacklist items to allow ${stream.name}',
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => blacklist.deleteToAllow(_message, stream),
                      child: Text(
                        'Delete blacklist items to allow ${stream.name}',
                      ),
                    ),
                  ],
                ),
                child: Tooltip(
                  preferBelow: false,
                  verticalOffset: 10,
                  message: 'Blacklisted from ${stream.name}',
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      iconTheme: IconThemeData(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                    ),
                    child: stream.disabledIcon,
                  ),
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
    required String message,
    Widget? trailing,
    Color? tileColor,
    void Function(TextSelection, SelectionChangedCause?)? onSelectionChanged,
    Widget Function(BuildContext, EditableTextState)? contextMenuBuilder,
  })  : _message = message,
        _trailing = trailing,
        _tileColor = tileColor,
        _onSelectionChanged = onSelectionChanged,
        _contextMenuBuilder = contextMenuBuilder;

  final String _message;
  final Widget? _trailing;
  final Color? _tileColor;
  final void Function(TextSelection, SelectionChangedCause?)?
      _onSelectionChanged;
  final Widget Function(BuildContext, EditableTextState)? _contextMenuBuilder;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        minVerticalPadding: 0,
        minTileHeight: 0,
        tileColor: _tileColor ?? Theme.of(context).colorScheme.surfaceContainer,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: SelectableText(
                _message,
                key: PageStorageKey(
                  'ChatViewSmoothListViewSelectableText$_message',
                ),
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                onSelectionChanged: _onSelectionChanged,
                contextMenuBuilder: _contextMenuBuilder,
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
            if (_trailing != null) _trailing,
          ],
        ),
      ),
    );
  }
}

class _InstanceChatMessage extends StatefulWidget {
  const _InstanceChatMessage(
    String message,
  ) : _message = message;

  final String _message;

  @override
  State<_InstanceChatMessage> createState() => _InstanceChatMessageState();
}

class _InstanceChatMessageState extends State<_InstanceChatMessage> {
  TextSelection? _selection;

  @override
  Widget build(BuildContext context) {
    return Consumer<BlacklistModel>(
      builder: (context, blacklist, child) {
        return _ChatMessage(
          tileColor: BlacklistModel.filterAny(widget._message)
              ? null
              : const Color.fromARGB(30, 206, 20, 7),
          onSelectionChanged: _onSelectionChanged,
          contextMenuBuilder: _contextMenuBuilder,
          message: widget._message,
          trailing: _BlacklistIcons(widget._message),
        );
      },
    );
  }

  void _onSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) =>
      setState(() {
        _selection = selection;
      });

  Widget _contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final List<ContextMenuButtonItem> buttonItems =
        editableTextState.contextMenuButtonItems;
    var divHeightAdd = 0;
    var divHeightDeleteEdit = 0;

    final String textInside = _selection?.textInside(widget._message) ?? '';
    if (textInside.isNotEmpty && textInside != widget._message) {
      BlacklistMatch match;
      if (widget._message.startsWith(textInside)) {
        match = BlacklistMatch.startsWith;
      } else if (widget._message.endsWith(textInside)) {
        match = BlacklistMatch.endsWith;
      } else {
        match = BlacklistMatch.contains;
      }

      if (!BlacklistModel.contains(widget._message)) {
        buttonItems.add(
          ContextMenuButtonItem(
            onPressed: () {
              final BlacklistModel blacklist =
                  Provider.of<BlacklistModel>(context, listen: false);
              ContextMenuController.removeAny();
              if (blacklist.add(widget._message)) {
                Toaster.showToast('Added message to blacklist.');
              }
            },
            label: 'Add message to blacklist',
          ),
        );
        divHeightAdd++;
      }

      if (!BlacklistModel.contains(textInside, blacklistMatch: match)) {
        buttonItems.add(
          ContextMenuButtonItem(
            onPressed: () {
              final BlacklistModel blacklist =
                  Provider.of<BlacklistModel>(context, listen: false);
              ContextMenuController.removeAny();
              if (blacklist.add(textInside, blacklistMatch: match)) {
                Toaster.showToast('Added selection to blacklist.');
              }
            },
            label: switch (match) {
              BlacklistMatch.exact => 'Add selection to blacklist',
              BlacklistMatch.startsWith =>
                'Blacklist messages that start with the selection',
              BlacklistMatch.endsWith =>
                'Blacklist messages that end with the selection',
              BlacklistMatch.contains =>
                'Blacklist messages that contain the selection',
            },
          ),
        );

        divHeightAdd++;
      }
    }

    if (!BlacklistModel.filterAny(widget._message)) {
      buttonItems.add(
        ContextMenuButtonItem(
          onPressed: () {
            final BlacklistModel blacklist =
                Provider.of<BlacklistModel>(context, listen: false);
            ContextMenuController.removeAny();
            blacklist.deleteAny(widget._message);
          },
          label: 'Delete blacklist items to allow message',
        ),
      );
      divHeightDeleteEdit++;
    }

    buttonItems.add(
      ContextMenuButtonItem(
        onPressed: () async {
          ContextMenuController.removeAny();
          await BlacklistModel.edit();
        },
        label: 'Edit blacklist',
      ),
    );
    divHeightDeleteEdit++;

    final List<Widget> buttons = buttonItems
        .map<Widget>(
          (buttonItem) => TextButton(
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(
                Size(double.infinity, 50),
              ),
              alignment: Alignment.centerLeft,
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(),
              ),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              overlayColor: WidgetStateProperty.fromMap({
                WidgetState.hovered: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHigh
                    .withAlpha(100),
              }),
              foregroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onPressed: buttonItem.onPressed,
            child: Text(
              CupertinoTextSelectionToolbarButton.getButtonLabel(
                context,
                buttonItem,
              ),
            ),
          ),
        )
        .toList();

    if (divHeightAdd > 0) {
      buttons.insert(
        buttons.length - divHeightAdd - divHeightDeleteEdit,
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Divider(
            height: 12,
            thickness: 2,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
      );
    }

    if (divHeightDeleteEdit > 0) {
      buttons.insert(
        buttons.length - divHeightDeleteEdit,
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Divider(
            height: 12,
            thickness: 2,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
      );
    }

    return AdaptiveTextSelectionToolbar(
      anchors: editableTextState.contextMenuAnchors,
      children: buttons,
    );
  }
}
