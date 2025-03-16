import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'instance_manager.dart';
import 'log_stream.dart';

/// Manages multiple streams of log messages from "latest.log".
class LogRiver {
  /// Manages multiple streams of log messages from "latest.log".
  LogRiver(
    String path, {
    required VoidCallback notifyListeners,
    required InstanceController instance,
  })  : _notifyListeners = notifyListeners,
        _instance = instance {
    unawaited(divertRiver(path));
  }

  final List<_LogStreamSubscription> _subscriptions = [];
  final VoidCallback _notifyListeners;
  final InstanceController _instance;

  LogStream? _logStream;
  StreamSubscription<FileSystemEvent>? _logWatch;

  Future<void> _unsubscribe() async {
    await _subscriptions.map((sub) => sub._unsubscribe()).wait;
  }

  Future<void> _resubscribe() async {
    await _subscriptions.map((sub) => sub._resubscribe(_logStream)).wait;
  }

  /// Adds a subscription to the river.
  void addSubscription({
    required bool Function() isEnabled,
    required void Function(String) onData,
    void Function()? onCancel,
    bool Function(String)? where,
    String Function(String)? map,
  }) {
    final subscription = _LogStreamSubscription(
      logStream: _logStream,
      isEnabled: isEnabled,
      onData: onData,
      onCancel: onCancel,
      where: where,
      map: map,
    );

    _subscriptions.add(subscription);
  }

  /// Starts up the river with a source log file.
  Future<void> divertRiver(String path) async {
    Future<void> killStreamAndListeners() async {
      _logStream?.destroy();
      _logStream = null;

      await _unsubscribe();

      _notifyListeners();
    }

    Future<void> restartStreamAndListeners(String path) async {
      _logStream?.destroy();
      _logStream = null;

      await _unsubscribe();

      if (File(path).existsSync()) {
        _logStream = LogStream(path, _instance);
        await _resubscribe();
      }

      _notifyListeners();
    }

    // ** Logic starts here ** //
    await _logWatch?.cancel();

    await restartStreamAndListeners(path);

    _logWatch = Directory(p.dirname(path)).watch().listen((event) async {
      if (event.path == path) {
        switch (event.runtimeType) {
          case const (FileSystemDeleteEvent):
          case const (FileSystemMoveEvent):
            await killStreamAndListeners();
          case const (FileSystemCreateEvent):
            await restartStreamAndListeners(path);
        }
      } else if (event is FileSystemMoveEvent && event.destination == path) {
        await restartStreamAndListeners(path);
      }
    });
  }

  /// Turns streams on or off depending on current enabled status.
  Future<void> checkEnabled() async {
    await _subscriptions.map((sub) => sub.checkEnabled()).wait;
  }

  /// Destroys the river and all streams.
  Future<void> destroy() async {
    await _logWatch?.cancel();
    _logWatch = null;

    _logStream?.destroy();
    _logStream = null;

    await _unsubscribe();
  }
}

class _LogStreamSubscription {
  _LogStreamSubscription({
    required LogStream? logStream,
    required bool Function() isEnabled,
    required void Function(String) onData,
    void Function()? onCancel,
    bool Function(String)? where,
    String Function(String)? map,
  })  : _logStream = logStream,
        _isEnabled = isEnabled,
        _onData = onData,
        _onCancel = onCancel,
        _streamWhere = where ?? ((_) => true),
        _streamMap = map ?? ((line) => line) {
    unawaited(checkEnabled());
  }

  LogStream? _logStream;

  final bool Function() _isEnabled;
  final Function(String) _onData;
  final Function()? _onCancel;
  final bool Function(String) _streamWhere;
  final String Function(String) _streamMap;

  var _enabled = false;

  /// Starts or stops the stream.
  Future<void> checkEnabled() async {
    final bool value = _isEnabled();

    if (value == _enabled) return;

    _enabled = value;

    await _resubscribe(_logStream);
  }

  StreamSubscription<String>? _subscription;

  Future<void> _resubscribe(LogStream? logStream) async {
    _logStream = logStream;

    await _unsubscribe();

    if (logStream == null || !_enabled) return;

    final Stream<String> filteredStream =
        _logStream!.stream.where(_streamWhere).map(_streamMap);

    _subscription = filteredStream.listen(
      _onData,
      onError: (error) async {
        if (error is PathNotFoundException) {
          await _unsubscribe();
        } else if (kDebugMode) {
          throw error;
        }
      },
    );
  }

  Future<void> _unsubscribe() async {
    await _subscription?.cancel();
    _subscription = null;

    _onCancel?.call();
  }
}
