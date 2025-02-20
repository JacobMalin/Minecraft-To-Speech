import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:provider/provider.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import 'file_theme.dart';
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
    return ResizableContainer(
      direction: Axis.horizontal,
      children: [
        ResizableChild(
          divider: ResizableDivider(
            thickness: 3,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          size: ResizableSize.pixels(170, min: 70),
          child: FileList(),
        ),
        ResizableChild(
          size: ResizableSize.expand(min: 272),
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
        if (selectedIndex != files.index) {
          selectedIndex = files.index;
          _controller.text = selected.name;
        }

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Switch(
                          value: selected.isEnabled,
                          onChanged: (enabled) =>
                              files.updateWith(enabled: enabled),
                          activeColor: fileTheme.green,
                          inactiveThumbColor: fileTheme.red,
                          inactiveTrackColor: fileTheme.red.withAlpha(180),
                          hoverColor: Colors.transparent,
                          trackOutlineColor:
                              WidgetStatePropertyAll(Colors.transparent),
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
                                      files.updateWith(
                                          discord: !selected.isDiscord);
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          fillColor: fileTheme.green.withAlpha(150),
                          selectedColor:
                              Theme.of(context).colorScheme.onSurface,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text("TTS"),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text("Discord"),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => files.openSecondFolder(),
                          icon: Icon(Icons.folder_open),
                        ),
                      ],
                    ),
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

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  var messages = ["<qwaszx100> aaa", "<qwaszx100> iii", for (int i = 0; i < 20; i++)"<qwaszx100> $i"];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 41) return Spacer();

        return SmoothListView.builder(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 24),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) => Material(
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              minVerticalPadding: 0,
              minTileHeight: 0,
              tileColor: Theme.of(context).colorScheme.surfaceContainer,
              title: Text(
                messages[index],
                style: TextStyle(
                  fontFamily: 'Minecraft', // Your Minecraft font
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                  shadows: [
                    Shadow(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(70),
                      offset: Offset(2.49, 2.49),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
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
              duration: const Duration(milliseconds: 200),
              itemCount: files.length,
              itemBuilder: (context, index) =>
                  FileTile(index, files[index], constraints.maxHeight),
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

        return ListTile(
          minTileHeight: 0,
          contentPadding: EdgeInsets.only(left: 10, right: 10),
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
          tileColor: file.isEnabled ? fileTheme.green : fileTheme.red,
          hoverColor:
              file.isEnabled ? fileTheme.greenHover : fileTheme.redHover,
          selectedTileColor: Theme.of(context).colorScheme.secondary,
          onTap: () => files.choose(index),
          splashColor: Colors.transparent,
          textColor: Theme.of(context).colorScheme.secondary,
          selectedColor: file.isEnabled ? fileTheme.green : fileTheme.red,
          selected: selected,
        );
      },
    );
  }
}
