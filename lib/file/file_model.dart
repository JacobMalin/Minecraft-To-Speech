import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'file_settings.dart';

class FileModel extends ChangeNotifier {
  final files = <FileSettings>[
    FileSettings.fromPath("a", enabled: true),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
    FileSettings.fromPath("b c d e f g h i j k l m n o p q r s t u v w x y z"),
    FileSettings.fromPath("c"),
  ];
  int index = -1;
  late ScrollController controller = ScrollController();

  get length => files.length;
  get selected => index >= 0 && index < files.length ? files[index] : null;

  operator [](index) => files[index];

  choose(index) {
    this.index = index;
    notifyListeners();
  }

  add() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['log'],
    );

    if (result == null) return; // If the user cancels the prompt, exit

    files.add(FileSettings.fromPath(result.files.single.path!));
    notifyListeners();
  }

  remove() {
    if (files.isNotEmpty && index >= 0) {
      files.removeAt(index);
      index = min(index, files.length - 1);

      notifyListeners();
    }
  }
}
