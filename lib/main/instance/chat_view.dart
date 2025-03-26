import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import '../../blacklist/blacklist.dart';
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
          itemBuilder: (context, index) => Material(
            child: ChatMessage(message: selected.messages[index]),
          ),
        );
      },
      child: Container(),
    );
  }
}

/// A singluar chat message styled to look like Minecraft chat.
class ChatMessage extends StatefulWidget {
  /// Constructor for the chat message.
  const ChatMessage({
    required String message,
    Widget? trailing,
    super.key,
  })  : _message = message,
        _trailing = trailing;

  final String _message;
  final Widget? _trailing;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  TextSelection? _selection;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      minVerticalPadding: 0,
      minTileHeight: 0,
      tileColor: Theme.of(context).colorScheme.surfaceContainer,
      title: SelectableText(
        widget._message,
        key: PageStorageKey(
          'ChatViewSmoothListViewSelectableText${widget._message}',
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        onSelectionChanged: (selection, cause) => setState(() {
          _selection = selection;
        }),
        contextMenuBuilder: (context, editableTextState) {
          final List<ContextMenuButtonItem> buttonItems =
              editableTextState.contextMenuButtonItems;

          final String textInside =
              _selection?.textInside(widget._message) ?? '';
          if (textInside.isEmpty) {
            buttonItems.add(
              ContextMenuButtonItem(
                onPressed: () {
                  ContextMenuController.removeAny();
                  Blacklist.add(widget._message);
                },
                label: 'Add to blacklist',
              ),
            );
          } else {
            BlacklistMatch match;
            if (widget._message == textInside) {
              match = BlacklistMatch.exact;
            } else if (widget._message.startsWith(textInside)) {
              match = BlacklistMatch.startsWith;
            } else if (widget._message.endsWith(textInside)) {
              match = BlacklistMatch.endsWith;
            } else {
              match = BlacklistMatch.contains;
            }

            buttonItems.add(
              ContextMenuButtonItem(
                onPressed: () {
                  ContextMenuController.removeAny();
                  Blacklist.add(textInside, blacklistMatch: match);
                },
                label: switch (match) {
                  BlacklistMatch.exact => 'Add selection to blacklist',
                  BlacklistMatch.startsWith =>
                    'Blacklist phrases that starts with the selection',
                  BlacklistMatch.endsWith =>
                    'Blacklist phrases that ends with the selection',
                  BlacklistMatch.contains =>
                    'Blacklist phrases that contains the selection',
                },
              ),
            );
          }

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

          buttons.insert(
            buttons.length - 1,
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Divider(
                height: 12,
                thickness: 2,
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
            ),
          );

          return AdaptiveTextSelectionToolbar(
            anchors: editableTextState.contextMenuAnchors,
            children: buttons,
          );
        },
        style: TextStyle(
          fontFamily: 'Minecraft', // Your Minecraft font
          fontSize: 20,
          height: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shadows: [
            Shadow(
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(70),
              offset: const Offset(2.49, 2.49),
            ),
          ],
        ),
      ),
      trailing: widget._trailing,
    );
  }
}
