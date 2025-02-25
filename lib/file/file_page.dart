import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import '../setup/theme_setup.dart';
import 'file_manager.dart';
import 'file_model.dart';

class FilePage extends StatefulWidget {
  const FilePage({
    super.key,
  });

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  @override
  Widget build(BuildContext context) {
    // return ResizableContainer(
    //   direction: Axis.horizontal,
    //   children: [
    //     ResizableChild(
    //       divider: ResizableDivider(
    //         thickness: 3,
    //         color: Theme.of(context).colorScheme.surfaceContainerHighest,
    //       ),
    //       size: ResizableSize.pixels(170, min: 70),
    //       child: FileList(),
    //     ),
    //     ResizableChild(
    //       size: ResizableSize.expand(min: 272),
    //       child: FileInfoPage(),
    //     ),
    //   ],
    // );

    return Row(
      children: [
        Flexible(
          flex: 3,
          child: FileList(),
        ),
        Flexible(
          flex: 7,
          child: FileInfoPage(),
        ),
      ],
    );
  }
}

class FileInfoPage extends StatefulWidget {
  const FileInfoPage({
    super.key,
  });

  @override
  State<FileInfoPage> createState() => _FileInfoPageState();
}

class _FileInfoPageState extends State<FileInfoPage> {
  late TextEditingController _controller;
  late int? selectedIndex;

  @override
  void initState() {
    super.initState();
    final files = Provider.of<FileModel>(context, listen: false);
    selectedIndex = files.index;
    _controller = TextEditingController(text: files.selected?.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileModel>(
      builder: (context, files, child) {
        if (files.index == null) {
          selectedIndex = null;
          return child!;
        }

        FileManager selected = files.selected!;
        if (selectedIndex != files.index) selectedIndex = files.index;
        if (_controller.text != selected.name) _controller.text = selected.name;

        final fileTheme = Theme.of(context).extension<FileTheme>()!;

        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Spacer(),
                        Flexible(
                          flex: 4,
                          child: TextField(
                            controller: _controller,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                            onChanged: (newName) =>
                                files.updateWith(name: newName),
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      // Makes spaces non-breaking and slashes breaking
                      selected.path
                          .replaceAll(" ", "\u202f")
                          .replaceAll("\\", "\\\u200b"),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 25),
                    FileInfoButtons(selected: selected, fileTheme: fileTheme),
                  ],
                ),
              ),
              Expanded(child: ChatView()),
            ],
          ),
        );
      },
      child: Consumer<FileModel>(builder: (context, files, child) {
        return Align(
          alignment: Alignment.center,
          child: files.length == 0
              ? Text("Add a file to get started!")
              : Text("No file selected."),
        );
      }),
    );
  }
}

class FileInfoButtons extends StatelessWidget {
  const FileInfoButtons({
    super.key,
    required this.selected,
    required this.fileTheme,
  });

  final FileManager selected;
  final FileTheme fileTheme;

  @override
  Widget build(BuildContext context) {
    return Consumer<FileModel>(builder: (context, files, child) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          Switch(
            value: selected.isEnabled,
            onChanged: (enabled) => files.updateWith(enabled: enabled),
            activeColor: fileTheme.green,
            inactiveThumbColor: fileTheme.red,
            inactiveTrackColor: fileTheme.red.withAlpha(180),
            hoverColor: Colors.transparent,
            trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
            thumbIcon: WidgetStatePropertyAll(
              Icon(
                Icons.power_settings_new,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          ToggleButtons(
            isSelected: [selected.isTts, selected.isDiscord],
            onPressed: selected.isEnabled
                ? (index) {
                    switch (index) {
                      case 0:
                        files.updateWith(tts: !selected.isTts);
                      case 1:
                        files.updateWith(discord: !selected.isDiscord);
                    }
                  }
                : null,
            borderRadius: BorderRadius.circular(10),
            fillColor: fileTheme.green.withAlpha(150),
            selectedColor: Theme.of(context).colorScheme.onSurface,
            splashColor: Colors.transparent,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text("TTS"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text("Discord"),
              ),
            ],
          ),
          IconButton(
            onPressed: () => files.openSecondFolder(),
            icon: Icon(Icons.folder_open),
            splashColor: Colors.transparent,
          ),
        ],
      );
    });
  }
}

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxHeight < 41) return Container();

      return Consumer<FileModel>(
        builder: (context, files, child) {
          FileManager? selected = files.selected;
          if (selected == null) return child!;

          return SmoothListView.builder(
            key: PageStorageKey('ChatViewSmoothListView${selected.path}'),
            duration: const Duration(milliseconds: 400),
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 20),
            reverse: true,
            itemCount: selected.messages.length,
            itemBuilder: (context, index) => Material(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                minVerticalPadding: 0,
                minTileHeight: 0,
                tileColor: Theme.of(context).colorScheme.surfaceContainer,
                title: SelectableText(
                  selected.messages[index],
                  key: PageStorageKey(
                    'ChatViewSmoothListViewSelectableText${selected.path}$index',
                  ),
                  textHeightBehavior: TextHeightBehavior(
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
                        offset: Offset(2.49, 2.49),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: Container(),
      );
    });
  }
}

class FileList extends StatelessWidget {
  const FileList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Consumer<FileModel>(
        builder: (context, files, child) {
          return LayoutBuilder(builder: (context, constraints) {
            return SmoothListView.builder(
              key: PageStorageKey('FileListSmoothListView'),
              duration: const Duration(milliseconds: 500),
              itemCount: files.length + 1,
              itemBuilder: (context, index) {
                if (index < files.length) {
                  return FileTile(index, files[index], constraints.maxHeight);
                }

                return ListTile(
                  leading: Icon(Icons.add),
                  title: Text("Add File"),
                  onTap: () => files.add(),
                );
              },
            );
          });
        },
      ),
    );
  }
}

class FileTile extends StatelessWidget {
  const FileTile(
    this.index,
    this.file,
    this.maxHeight, {
    super.key,
  });

  final int index;
  final FileManager file;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final fileTheme = Theme.of(context).extension<FileTheme>()!;

    return Consumer<FileModel>(
      builder: (context, files, child) {
        bool selected = files.index == index;

        return GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(
            context,
            details.globalPosition,
            removeFile: () => files.remove(index),
          ),
          child: ListTile(
            minTileHeight: 0,
            contentPadding: EdgeInsets.only(left: 10, right: 10),
            tileColor: file.isEnabled ? fileTheme.green : fileTheme.red,
            hoverColor:
                file.isEnabled ? fileTheme.greenHover : fileTheme.redHover,
            selectedTileColor: Theme.of(context).colorScheme.secondary,
            splashColor: Colors.transparent,
            textColor: Theme.of(context).colorScheme.secondary,
            selectedColor: file.isEnabled ? fileTheme.green : fileTheme.red,
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              // Makes colon and space non-breaking
              file.path.replaceFirst(":", ":\u2060").replaceAll(" ", "\u202f"),
              maxLines: maxHeight > 350 ? 3 : (maxHeight > 250 ? 2 : 1),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => files.choose(index),
            selected: selected,
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, Offset position,
      {required Function removeFile}) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      menuPadding: EdgeInsets.all(0),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: [
        PopupMenuItem(
          value: "remove",
          height: 40,
          child: Text(
            "Remove",
          ),
        ),
      ],
    );

    if (result == "remove") removeFile();
  }
}
