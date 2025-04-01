import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The context menu for text fields.
class TextFieldContext {
  /// The builder for the context menu.
  static Widget builder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final List<ContextMenuButtonItem> buttonItems =
        editableTextState.contextMenuButtonItems;

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

    return AdaptiveTextSelectionToolbar(
      anchors: editableTextState.contextMenuAnchors,
      children: buttons,
    );
  }
}
