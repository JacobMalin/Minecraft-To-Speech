import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../setup/hive_setup.dart';
import '../setup/window_setup.dart';
import '../toaster.dart';
import 'instance_manager.dart';

class InstanceModel extends ChangeNotifier {
  final Box settingsBox = HiveSetup.settingsBox();
  final List<InstanceController> instances = [];

  int? get selectedIndex => settingsBox['index'];
  set selectedIndex(final int? index) => settingsBox['index'] = index;

  int get length => instances.length;
  InstanceController? get selected =>
      selectedIndex != null && selectedIndex! < instances.length
          ? instances[selectedIndex!]
          : null;

  InstanceModel() {
    final Box instancesBox = HiveSetup.instancesBox();

    if (settingsBox.containsKey('paths')) {
      for (String path in settingsBox['paths']) {
        instances.add(InstanceController(path, notifyListeners));
      }

      // Remove broken files
      final List<dynamic> paths = settingsBox['paths'];
      for (String path in instancesBox.keys) {
        if (!paths.contains(path)) instancesBox.delete(path);
      }
    } else {
      instancesBox.clear();
      selectedIndex = null;
    }

    if (selectedIndex != null) {
      selectedIndex = min(selectedIndex!, instances.length - 1);
    }
    if (selectedIndex == -1) selectedIndex = null;
  }

  InstanceController operator [](final index) => instances[index];

  void choose(final int? index) {
    selectedIndex = selectedIndex != index ? selectedIndex = index : null;
    notifyListeners();
  }

  Future<void> add() async {
    // TODO: Add easier onboarding process for adding instances
    /* In doing so, 
     * - Rephrase all user-facing instances of log to instance
     * - Remove references to log files such as changing user-facing file path
     *   to a directory path for the instance
     * - Rename "Add log" to "Add instance from log" (mention latest.log)
     * - Maybe move add instance from log to submenu that will be opened in the 
     *   onboarding process
     * - Check so that users can only add "latest.log" files.
    */

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Minecraft Log File to Monitor',
      type: FileType.custom,
      allowedExtensions: ['log'],
    );

    unawaited(WindowSetup.focusAndBringToFront());

    if (result == null) return; // If the user cancels the prompt, exit

    final String path = result.files.single.path!;

    // If instance already exists, select the instance and return
    for (var i = 0; i < instances.length; i++) {
      if (instances[i].path == path) {
        selectedIndex = i;
        notifyListeners();

        Toaster.showToast('Instance already added!');

        return;
      }
    }

    // Else if new instance,
    instances.add(InstanceController(path, notifyListeners));
    settingsBox['paths'] =
        instances.map((final instance) => instance.path).toList();

    selectedIndex = instances.length - 1; // Select newly added instance
    notifyListeners();
  }

  void remove([int? index]) {
    index ??= selectedIndex;

    if (index == null || index >= instances.length || instances.isEmpty) {
      Toaster.showToast('No instance selected!');
      return;
    }

    instances.removeAt(index).cleanBox();
    settingsBox['paths'] =
        instances.map((final instance) => instance.path).toList();

    if (selectedIndex != null) {
      selectedIndex = min(selectedIndex!, instances.length - 1);
    }
    if (selectedIndex == -1) selectedIndex = null;

    notifyListeners();
  }

  void updateWith(
      {final int? index,
      final String? name,
      final bool? enabled,
      final bool? tts,
      final bool? discord}) {
    final int? indexOrSelected = index ?? selectedIndex;

    if (indexOrSelected != null) {
      instances[indexOrSelected].updateWith(
        name: name,
        enabled: enabled,
        tts: tts,
        discord: discord,
      );

      notifyListeners();
    }
  }

  Future<void> openSecondFolder() async {
    await selected?.openSecondFolder();
  }
}
