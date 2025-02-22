import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import '../dialog_service.dart';
import '../setup/window_setup.dart';
import 'file_filter.dart';
import 'file_manager.dart';

class FileModel extends ChangeNotifier {
  final settingsBox = Hive.box(name: 'settings');
  final List<FileManager> files = [];

  int? get index => settingsBox['index'];
  set index(int? index) => settingsBox['index'] = index;

  get length => files.length;
  FileManager? get selected =>
      index != null && index! < files.length ? files[index!] : null;

  FileModel() {
    final filesBox = Hive.box(name: 'files');

    if (settingsBox.containsKey('paths')) {
      for (var path in settingsBox['paths']) {
        files.add(FileManager(path, notifyListeners));
      }

      // Remove broken files
      final List<dynamic> paths = settingsBox['paths'];
      for (String path in filesBox.keys) {
        if (!paths.contains(path)) filesBox.delete(path);
      }
    } else {
      filesBox.clear();
      index = null;
    }

    if (index != null) index = min(index!, files.length - 1);
    if (index == -1) index = null;
  }

  operator [](index) => files[index];

  choose(int? index) {
    this.index = this.index != index ? this.index = index : null;
    notifyListeners();
  }

  add() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: "Select Minecraft Log File to Monitor",
      type: FileType.custom,
      allowedExtensions: ['log'],
    );

    WindowSetup.focusAfterPicker();

    if (result == null) return; // If the user cancels the prompt, exit

    var path = result.files.single.path!;

    // If file already exists, select the file and return
    for (var i = 0; i < files.length; i++) {
      if (files[i].path == path) {
        index = i;
        notifyListeners();
        return;
      }
    }

    // Else if new file,
    files.add(FileManager(path, notifyListeners));
    settingsBox['paths'] = files.map((file) => file.path).toList();

    index = files.length - 1; // Select newly added file
    notifyListeners();
  }

  remove([int? index]) {
    index ??= this.index;

    if (files.isNotEmpty && index != null && index < files.length) {
      files.removeAt(index).cleanBox();
      settingsBox['paths'] = files.map((file) => file.path).toList();

      if (this.index != null) this.index = min(this.index!, files.length - 1);
      if (this.index == -1) this.index = null;

      notifyListeners();
    }
  }

  updateWith(
      {int? index, String? name, bool? enabled, bool? tts, bool? discord}) {
    var indexOrSelected = index ?? this.index;

    if (indexOrSelected != null) {
      files[indexOrSelected].updateWith(
        name: name,
        enabled: enabled,
        tts: tts,
        discord: discord,
      );

      notifyListeners();
    }
  }

  openSecondFolder() {
    selected?.openSecondFolder();
  }

  static process() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: "Select Minecraft Log File to Process",
      type: FileType.custom,
      allowedExtensions: ['log'],
      allowMultiple: true,
    );

    WindowSetup.focusAfterPicker();

    if (result == null) return; // If the user cancels the prompt, exit

    await result.paths.map(_processFile).wait;

    DialogService.showDialogElsewhere(
      builder: (context) => FutureBuilder(
        future: null,
        builder: (context, snapshot) {
          return AlertDialog(
            title: const Text(
              "File Processed",
              textAlign: TextAlign.center,
            ),
            content: Text(
              "File processed and saved",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        }
      ),
    );
  }

  static Future<void> _processFile(String? path) async {
    final inFile = File(path!);

    final pathWithoutExt = p.withoutExtension(path);
    final extension = p.extension(path);
    final outFile = File("$pathWithoutExt-cleaned$extension");

    final (bool inExists, bool outExists) =
        await (inFile.exists(), outFile.exists()).wait;
    if (!inExists || outExists) return;

    final stream = inFile.openRead();
    final lines = utf8.decoder.bind(stream).transform(const LineSplitter());
    final filtered = lines.where(FileFilter.onlyChat).map(FileFilter.commonMap);
    final uiFilter = filtered.map(FileFilter.discordMap);

    final IOSink outSink = outFile.openWrite();
    outSink.writeAll(await uiFilter.toList(), "\n");
    outSink.close();
  }
}
