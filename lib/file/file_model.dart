import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:window_manager/window_manager.dart';

import 'file_manager.dart';

class FileModel extends ChangeNotifier {
  final settingsBox = Hive.box(name: 'settings');
  final List<FileManager> files = [];

  int index = -1;
  late ScrollController controller = ScrollController();

  get length => files.length;
  FileManager? get selected =>
      index >= 0 && index < files.length ? files[index] : null;

  FileModel() {
    if (settingsBox.containsKey('paths')) {
      for (var path in settingsBox['paths']) {
        files.add(FileManager(path));
      }
    }
  }

  operator [](index) => files[index];

  choose(int index) {
    this.index = this.index != index ? this.index = index : -1;
    notifyListeners();
  }

  add() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['log'],
    );

    // Focus window after picker
    windowManager.focus();

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
    files.add(FileManager(path));
    settingsBox['paths'] = files.map((file) => file.path).toList();

    index = files.length - 1; // Select newly added file
    notifyListeners();
  }

  remove() {
    if (files.isNotEmpty && index >= 0) {
      files.removeAt(index).cleanBox();
      settingsBox['paths'] = files.map((file) => file.path).toList();

      index = min(index, files.length - 1);

      notifyListeners();
    }
  }

  updateWith(
      {int? index, String? name, bool? enabled, bool? tts, bool? discord}) {
    var indexOrSelected = index ?? this.index;

    files[indexOrSelected].updateWith(
      name: name,
      enabled: enabled,
      tts: tts,
      discord: discord,
    );

    notifyListeners();
  }

  openSecondFolder() {
    selected?.openSecondFolder();
  }
}
