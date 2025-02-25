import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../setup/window_setup.dart';
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

    WindowSetup.focusAndBringToFront();

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
}
