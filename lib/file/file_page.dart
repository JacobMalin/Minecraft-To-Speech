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
        Container(),
      ],
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
          ),
          subtitle: Text(
            file.path.replaceFirst(":", ":\u2060"),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          tileColor: file.enabled ? fileTheme.green : fileTheme.red,
          hoverColor: file.enabled ? fileTheme.greenHover : fileTheme.redHover,
          selectedTileColor: Theme.of(context).colorScheme.secondary,
          onTap: () => files.choose(index),
          splashColor: Colors.transparent,
          textColor: Theme.of(context).colorScheme.secondary,
          selectedColor: file.enabled ? fileTheme.green : fileTheme.red,
          selected: selected,
        );
      },
    );
  }
}
