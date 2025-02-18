import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resizable_widget/resizable_widget.dart';
import 'package:smooth_list_view/smooth_list_view.dart';

import 'file_theme.dart';
import 'file_settings.dart';
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
    return ResizableWidget(
      percentages: [0.3, 0.7],
      separatorSize: 3,
      // This does not work perfectly and is duplicated in the Seperator class
      separatorColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      children: [
        FileList(),
        FileInfo(),
      ],
    );
  }
}

class FileInfo extends StatefulWidget {
  const FileInfo({
    super.key,
  });

  @override
  State<FileInfo> createState() => _FileInfoState();
}

class _FileInfoState extends State<FileInfo> {
  late TextEditingController _controller;
  late int selectedIndex;

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
        if (files.index == -1) return child!;

        FileSettings selected = files.selected!;
        if (selectedIndex != files.index) {
          selectedIndex = files.index;
          _controller.text = selected.name;
        }

        final fileTheme = Theme.of(context).extension<FileTheme>()!;

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Flexible(flex: 1, child: Container()),
                    Flexible(
                      flex: 4,
                      child: TextField(
                        controller: _controller,
                        // decoration: null,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                        onChanged: (newName) => files.fileWith(name: newName),
                      ),
                    ),
                    Flexible(flex: 1, child: Container()),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 35,
                  child: Text(
                    // Makes spaces non-breaking and slash breaking
                    selected.path
                        .replaceAll(" ", "\u202f")
                        .replaceAll("\\", "\\\u200b"),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ),
                SizedBox(height: 25),
                ClipRect(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        value: selected.isEnabled,
                        onChanged: (enabled) =>
                            files.fileWith(enabled: enabled),
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
                      SizedBox(width: 10),
                      ToggleButtons(
                        isSelected: [selected.isTts, selected.isDiscord],
                        onPressed: selected.isEnabled
                            ? (index) {
                                switch (index) {
                                  case 0:
                                    files.fileWith(tts: !selected.isTts);
                                  case 1:
                                    files.fileWith(
                                        discord: !selected.isDiscord);
                                }
                              }
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        fillColor: fileTheme.green.withAlpha(150),
                        selectedColor: Theme.of(context).colorScheme.onSurface,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Align(
        alignment: Alignment.center,
        child: Text("No File Selected"),
      ),
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
      child: ClipRect(
        child: Consumer<FileModel>(
          builder: (context, files, child) {
            return SmoothListView.builder(
              smoothScroll: true,
              controller: files.controller,
              duration: const Duration(milliseconds: 200),
              itemCount: files.length,
              itemBuilder: (context, index) => FileTile(index, files[index]),
            );
          },
        ),
      ),
    );
  }
}

class FileTile extends StatelessWidget {
  const FileTile(
    this.index,
    this.file, {
    super.key,
  });

  final int index;
  final FileSettings file;

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
            maxLines: 3,
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
