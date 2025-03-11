import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'log_filter.dart';

/// Manages multiple streams of log messages from "latest.log".
class LogRiver {
  /// Manages multiple streams of log messages from "latest.log".
  LogRiver(String path, {required VoidCallback notifyListeners})
      : _notifyListeners = notifyListeners {
    unawaited(divertRiver(path));
  }

  final List<_LogStreamSubscription> _subscriptions = [];
  final VoidCallback _notifyListeners;

  Stream<String>? _stream;
  StreamSubscription<FileSystemEvent>? _logWatch;

  /// Adds a subscription to the river.
  void addSubscription({
    required bool Function() isEnabled,
    required void Function(String) onData,
    void Function()? onCancel,
    bool Function(String)? where,
    String Function(String)? map,
  }) {
    final subscription = _LogStreamSubscription(
      stream: _stream,
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
    Stream<String> logStream(String path) async* {
      final log = File(path);

      int position = log.lengthSync();

      await for (final void _ in Stream.periodic(
        const Duration(milliseconds: 100),
      )) {
        final int fileLength = await log.length();
        if (fileLength < position) position = 0;

        final Stream<List<int>> stream = log.openRead(position);
        final Stream<String> lines =
            utf8.decoder.bind(stream).transform(const LineSplitter());
        await for (final line in lines) {
          if (line.isNotEmpty) yield line;
        }

        position = fileLength;
      }
    }

    Stream<String> makeStream(String path) => logStream(path)
        .where(LogFilter.onlyChat)
        .map(LogFilter.commonMap)
        .asBroadcastStream();

    Future<void> unsubscribe() async {
      await _subscriptions.map((sub) => sub._unsubscribe()).wait;
    }

    Future<void> resubscribe() async {
      await _subscriptions.map((sub) => sub._resubscribe(_stream)).wait;
    }

    Future<void> killStreamAndListeners() async {
      _stream = null;
      await unsubscribe();

      _notifyListeners();
    }

    Future<void> restartStreamAndListeners(String path) async {
      _stream = null;
      await unsubscribe();

      if (File(path).existsSync()) {
        _stream = makeStream(path);
        await resubscribe();
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
}

class _LogStreamSubscription {
  _LogStreamSubscription({
    required Stream<String>? stream,
    required bool Function() isEnabled,
    required void Function(String) onData,
    void Function()? onCancel,
    bool Function(String)? where,
    String Function(String)? map,
  })  : _stream = stream,
        _isEnabled = isEnabled,
        _onData = onData,
        _onCancel = onCancel,
        _streamWhere = where ?? ((_) => true),
        _streamMap = map ?? ((line) => line) {
    unawaited(checkEnabled());
  }

  final Stream<String>? _stream;

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

    await _resubscribe(_stream);
  }

  StreamSubscription<String>? _subscription;

  Future<void> _resubscribe(Stream<String>? stream) async {
    await _unsubscribe();

    if (stream == null || !_enabled) return;

    final Stream<String> filteredStream =
        stream.where(_streamWhere).map(_streamMap);

    _subscription = filteredStream.listen(
      _onData,
      onError: (error) async {
        if (error is PathNotFoundException) {
          await _unsubscribe();
        } else if (kDebugMode) {
          print('Error in log stream: $error');
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
