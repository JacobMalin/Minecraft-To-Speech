import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

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
            child: ChatMessage(selected: selected, index: index),
          ),
        );
      },
      child: Container(),
    );
  }
}

/// A singluar chat message styled to look like Minecraft chat.
class ChatMessage extends StatelessWidget {
  /// Constructor for the chat message.
  const ChatMessage({
    required InstanceController selected,
    required int index,
    super.key,
  })  : _selected = selected,
        _index = index;

  final InstanceController _selected;
  final int _index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      minVerticalPadding: 0,
      minTileHeight: 0,
      tileColor: Theme.of(context).colorScheme.surfaceContainer,
      title: SelectableText(
        _selected.messages[_index],
        key: PageStorageKey(
          'ChatViewSmoothListViewSelectableText${_selected.path}$_index',
        ),
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
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(70),
              offset: const Offset(2.49, 2.49),
            ),
          ],
        ),
      ),
    );
  }
}
