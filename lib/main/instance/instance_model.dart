import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../setup/dialog_service.dart';
import '../../setup/toaster.dart';
import '../../setup/window_setup.dart';
import 'add_instance_dialog.dart';
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
      selectedIndex = null;
    }

    if (selectedIndex != null) {
      selectedIndex = min(selectedIndex!, instances.length - 1);
    }
    if (selectedIndex == -1) selectedIndex = null;
  }

  /// List of instances opened by the user. These are generated at runtime from
  /// the paths stored in the settings box.
  final List<InstanceController> instances = [];

  /// Index of the currently selected instance. If no instance is selected, this
  /// value is null.
  int? get selectedIndex => InstanceBox.selectedIndex;
  set selectedIndex(int? index) => InstanceBox.selectedIndex = index;

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
    selectedIndex = selectedIndex != index ? selectedIndex = index : null;
    notifyListeners();
  }

  /// Pull up the add instance dialog.
  Future<void> add() async {
    await DialogService.showDialogElsewhere(
      builder: (context) {
        return const AddInstanceDialog();
      },
    );
  }

  /// Add an instance from a log file path. If the instance already exists,
  /// select the instance and return. Else, add the instance to the list of
  /// instances.
  void addFromLog(String path) {
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
    _updatePaths();

    selectedIndex = instances.length - 1; // Select newly added instance
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
    _updatePaths();

    if (selectedIndex != null) {
      selectedIndex = min(selectedIndex!, instances.length - 1);
    }
    if (selectedIndex == -1) selectedIndex = null;

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
    await updateWith(path: path);
    _updatePaths();

    notifyListeners();
  }

  /// Move the given instance up in the list of instances. If no index is
  /// provided, the selected instance is moved up.
  void moveUp([int? index]) {
    index ??= selectedIndex;

    if (index == null || index == 0) return;

    instances.swap(index, index - 1);
    _updatePaths();

    if (selectedIndex != null) {
      if (selectedIndex == index) {
        selectedIndex = selectedIndex! - 1;
      } else if (selectedIndex == index - 1) {
        selectedIndex = selectedIndex! + 1;
      }
    }

    notifyListeners();
  }

  /// Move the given instance down in the list of instances. If no index is
  /// provided, the selected instance is moved down.
  void moveDown([int? index]) {
    index ??= selectedIndex;

    if (index == null || index == instances.length - 1) return;

    instances.swap(index, index + 1);
    _updatePaths();

    if (selectedIndex != null) {
      if (selectedIndex == index) {
        selectedIndex = selectedIndex! + 1;
      } else if (selectedIndex == index + 1) {
        selectedIndex = selectedIndex! - 1;
      }
    }

    notifyListeners();
  }

  void _updatePaths() {
    InstanceBox.paths = instances.map((instance) => instance.path).toList();
  }

  /// Update an instance with the provided values. If no index is provided, the
  /// selected instance is updated.
  Future<void> updateWith({
    int? index,
    String? name,
    String? path,
    bool? enabled,
    bool? tts,
    bool? discord,
  }) async {
    final int? indexOrSelected = index ?? selectedIndex;

    if (indexOrSelected != null) {
      await instances[indexOrSelected].updateWith(
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
    await selected?.openInstanceDirectory();
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

/// Adds the swap function to lists.
extension SwappableList<E> on List<E> {
  /// Swap the elements at the provided indices.
  void swap(int first, int second) {
    final E temp = this[first];
    this[first] = this[second];
    this[second] = temp;
  }
}
