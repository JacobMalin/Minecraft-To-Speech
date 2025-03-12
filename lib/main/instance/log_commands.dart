import 'dart:async';

import '../../setup/path_formatting.dart';
import 'instance_manager.dart';
import 'log_filter.dart';
import 'tts_queue.dart';

/// Adds chat commands to the log stream.
class LogCommands {
  /// Adds chat commands to the log stream.
  LogCommands(InstanceController instance) : _instance = instance;

  static const _unknownCommand =
      'Unknown or incomplete command, see below for error';
  static const _mts = '/${PathFormatting.wordJoiner}mts';

  final InstanceController _instance;
  var _lastDataIsCommand = false;
  final _tts = TtsQueue();

  /// Adds chat commands to the log stream.
  StreamTransformer<String, String> get transformer =>
      StreamTransformer<String, String>.fromHandlers(
        handleData: _handleData,
      );

  Future<void> _handleData(String data, EventSink<String> sink) async {
    if (!_instance.isEnabled) {
      sink.add(data);
      return;
    }

    if (!_lastDataIsCommand) {
      if (data == _unknownCommand) {
        _lastDataIsCommand = true;
      } else {
        sink.add(data);
      }

      return;
    }

    // If last data was a failed command
    _lastDataIsCommand = data == _unknownCommand;
    final List<String> args = data.removeHereTag().split(' ');

    if (args[0] != 'mts') {
      sink
        ..add(_unknownCommand)
        ..add(data);
      return;
    }

    switch (args.elementAtOrNull(1)) {
      case 'help':
        sink.multiple([
          'MTS chat commands:',
          '$_mts help - Show this help message',
          '$_mts tts - Toggle text-to-speech',
          '$_mts tts clear - Clear the text-to-speech queue',
          '$_mts discord - Toggle discord output',
          '$_mts folder - Open the instance folder',
        ]);
      case 'tts':
        switch (args.elementAtOrNull(2)) {
          case null:
            if (_instance.isTts) {
              sink.add('Disabled text-to-speech');
              await _instance.updateWith(tts: false);
              _tts.speak('Disabled text-to-speech');
            } else {
              sink.add('Enabled text-to-speech');
              await _instance.updateWith(tts: true);
              _tts.speak('Enabled text-to-speech');
            }
          case 'clear':
            await _tts.clear();
            sink.add('Cleared text-to-speech queue');
          default:
            sink.multiple(['Did you mean:', '$_mts tts', '$_mts tts clear']);
        }
      case 'discord':
        if (_instance.isDiscord) {
          await _instance.updateWith(discord: false);
          sink.add('Disabled discord output');
        } else {
          sink.add('Enabled discord output');
          await _instance.updateWith(discord: true);
        }
      case 'folder':
        await _instance.openInstanceDirectory();
        sink.add('Opened instance folder');
      default:
        sink.multiple([
          'MTS chat commands!',
          'Run $_mts help for more info.',
        ]);
    }
  }
}

/// Sink multiple strings to an event sink.
extension SinkMultiple on EventSink<String> {
  /// Adds multiple strings to the sink.
  void multiple(List<String> events) {
    events.forEach(add);
  }
}
