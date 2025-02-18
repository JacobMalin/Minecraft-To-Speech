import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:window_manager/window_manager.dart';

import 'file_settings.dart';

class FileModel extends ChangeNotifier {
  final files = Hive.box(name: 'files');
  int index = -1;
  late ScrollController controller = ScrollController();

  get length => files.length;
  FileSettings? get selected =>
      index >= 0 && index < files.length ? files[index] : null;

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
    var file = FileSettings.fromPath(path);
    files.add(file);
    index = files.length - 1; // Select newly added file
    notifyListeners();
  }

  remove() {
    if (files.isNotEmpty && index >= 0) {
      files.deleteAt(index);
      index = min(index, files.length - 1);

      notifyListeners();
    }
  }

  fileWith({int? index, String? name, bool? enabled, bool? tts, bool? discord}) {
    var indexOrSelected = index ?? this.index;
    var file = files[indexOrSelected];

    if (name != null) file.name = name;
    if (enabled != null) file.isEnabled = enabled;
    if (tts != null) file.isTts = tts;
    if (discord != null) file.isDiscord = discord;

    files[indexOrSelected] = file;
    notifyListeners();
  }
}
