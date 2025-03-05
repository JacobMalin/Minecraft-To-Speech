import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../setup/window_setup.dart';
import '../../setup/toaster.dart';
import 'instance_manager.dart';

/// Model for the minecraft instances.
class InstanceModel extends ChangeNotifier {
  /// Constructor for the instance model.
  InstanceModel() {
    if (InstanceBox.paths.isNotEmpty) {
      // Remove broken files
      for (final String path in InstanceBox.infos.keys) {
        if (!InstanceBox.paths.contains(path)) InstanceBox.infos.delete(path);
      }

      for (final String path in InstanceBox.paths) {
        instances.add(InstanceController(path, notifyListeners));
      }
    } else {
      InstanceBox.infos.clear();
      _selectedIndex = null;
    }

    if (selectedIndex != null) {
      _selectedIndex = min(selectedIndex!, instances.length - 1);
    }
    if (selectedIndex == -1) _selectedIndex = null;
  }

  /// List of instances opened by the user. These are generated at runtime from
  /// the paths stored in the settings box.
  final List<InstanceController> instances = [];

  /// Index of the currently selected instance. If no instance is selected, this
  /// value is null.
  int? get selectedIndex => InstanceBox.selectedIndex;
  set _selectedIndex(int? index) => InstanceBox.selectedIndex = index;

  /// Number of instances.
  int get length => instances.length;

  /// Get the currently selected instance. If no instance is selected, this
  /// value is null.
  InstanceController? get selected =>
      selectedIndex != null && selectedIndex! < instances.length
          ? instances[selectedIndex!]
          : null;

  /// Get the instance at the provided index.
  InstanceController operator [](int index) => instances[index];

  /// Select an instance. If the instance is already selected, deselect it.
  void choose(int? index) {
    _selectedIndex = selectedIndex != index ? _selectedIndex = index : null;
    notifyListeners();
  }

  /// Add a new instance to the list of instances. If the instance already
  /// exists, select the instance.
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
        _selectedIndex = i;
        notifyListeners();

        Toaster.showToast('Instance already added!');

        return;
      }
    }

    // Else if new instance,
    instances.add(InstanceController(path, notifyListeners));
    InstanceBox.paths = instances.map((instance) => instance.path).toList();

    _selectedIndex = instances.length - 1; // Select newly added instance
    notifyListeners();
  }

  /// Remove an instance from the list of instances. If no index is provided,
  /// the currently selected instance is removed.
  void remove([int? index]) {
    index ??= selectedIndex;

    if (index == null || index >= instances.length || instances.isEmpty) {
      Toaster.showToast('No instance selected!');
      return;
    }

    instances.removeAt(index).cleanBox();
    InstanceBox.paths = instances.map((instance) => instance.path).toList();

    if (selectedIndex != null) {
      _selectedIndex = min(selectedIndex!, instances.length - 1);
    }
    if (selectedIndex == -1) _selectedIndex = null;

    notifyListeners();
  }

  /// Locate a missing instance. If the newly chosen instance already exists,
  /// send a toast and return. Else, change the path of the instance.
  Future<void> locate() async {
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
        Toaster.showToast(
          'Instance already added. Choose a different instance.',
        );

        return;
      }
    }

    // Else if new instance,
    updateWith(path: path);
    InstanceBox.paths = instances.map((instance) => instance.path).toList();

    notifyListeners();
  }

  /// Update an instance with the provided values. If no index is provided, the
  /// selected instance is updated.
  void updateWith({
    int? index,
    String? name,
    String? path,
    bool? enabled,
    bool? tts,
    bool? discord,
  }) {
    final int? indexOrSelected = index ?? selectedIndex;

    if (indexOrSelected != null) {
      instances[indexOrSelected].updateWith(
        name: name,
        path: path,
        enabled: enabled,
        tts: tts,
        discord: discord,
      );

      notifyListeners();
    }
  }

  /// Open the instance folder of the selected instance.
  Future<void> openInstanceFolder() async {
    await selected?.openInstanceFolder();
  }
}

/// A box for persistent instance data.
class InstanceBox {
  static final Box _pathsBox = Hive.box(name: 'paths');

  //// The selected instance index.
  static int? get selectedIndex => _pathsBox['selectedIndex'];
  static set selectedIndex(int? value) {
    _pathsBox['selectedIndex'] = value;
  }

  //// The list of instance paths.
  static List<String> get paths => [..._pathsBox['paths'] ?? []];
  static set paths(List<String> value) {
    _pathsBox['paths'] = value;
  }

  /// The list of instance infos.
  static Box<InstanceInfo> get infos =>
      Hive.box<InstanceInfo>(name: 'instances');
}
