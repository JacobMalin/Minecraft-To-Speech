import 'dart:convert';
import 'dart:io';

import 'instance_manager.dart';
import 'log_commands.dart';
import 'log_filter.dart';

/// A class that streams the log file.
class LogStream {
  /// A class that streams the log file.
  LogStream(String path, InstanceController instance) {
    stream = _makeStream(path, instance);
  }

  var _endStream = false;

  /// Stream of log messages.
  late Stream<String> stream;

  /// Stream the log file at the given path.
  Stream<String> _baseStream(String path) async* {
    final log = File(path);

    int position = log.lengthSync();

    await for (final void _ in Stream.periodic(
      const Duration(milliseconds: 100),
    ).takeWhile((_) => !_endStream)) {
      final int fileLength = log.lengthSync();
      if (fileLength < position) position = 0;

      final Stream<List<int>> stream = log.openRead(position);

      final Stream<String> lines =
          stream.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        position += utf8.encode(line).length + 2;

        if (line.isNotEmpty) yield line;
      }
    }
  }

  Stream<String> _makeStream(
    String path,
    InstanceController instance,
  ) =>
      _baseStream(path)
          .where(LogFilter.onlyChat)
          .map(LogFilter.commonMap)
          .transform(LogCommands(instance).transformer)
          .asBroadcastStream();

  /// End the stream.
  void destroy() {
    _endStream = true;
  }
}
