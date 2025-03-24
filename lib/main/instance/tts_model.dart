import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Queue for TTS (Text to Speech) messages.
class TtsModel {
  /// Get the singleton instance of the TTS queue.
  factory TtsModel() => _instance;

  // Constructor must be private
  TtsModel._();

  /// Singleton instance of the TTS queue.
  // ignore: unused_field
  static final _instance = TtsModel._();

  final _TtsStrategy _strategy = _Sapi5Strategy();

  /// Add a message to the TTS queue.
  void speak(String message) => _strategy.speak(message);

  /// Clear the TTS queue.
  Future<void> clear() async => _strategy.clear();

  /// Clean up the TTS queue.
  Future<void> destroy() async => _strategy.destroy();
}

/// Strategy for speaking TTS messages.
abstract class _TtsStrategy {
  /// Speak a message.
  void speak(String message);

  /// Clear the TTS queue.
  Future<void> clear();

  /// Clean up the TTS strategy.
  Future<void> destroy();
}

// Testing other TTS strategies currently
// ignore: unused_element
class _FlutterTtsStrategy implements _TtsStrategy {
  _FlutterTtsStrategy() {
    Future<void> configureTts() async {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(1);
      await _flutterTts.setVolume(1);
    }

    unawaited(configureTts());

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    Stream.periodic(const Duration(milliseconds: 100)).listen((_) async {
      if (_isSpeaking || _queue.isEmpty) return;

      _isSpeaking = true;
      final String message = _queue.removeFirst();
      await _flutterTts.speak(message);
    });
  }

  final _flutterTts = FlutterTts();
  final Queue _queue = Queue<String>();
  var _isSpeaking = false;

  @override
  void speak(String message) => _queue.add(message);

  @override
  Future<void> clear() async {
    _queue.clear();
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  @override
  Future<void> destroy() async => _flutterTts.stop();
}

class _Sapi5Strategy implements _TtsStrategy {
  _Sapi5Strategy() {
    Future<void> init() async {
      final String workingDir = kDebugMode
          ? Directory.current.path
          : p.join(
              Platform.environment['LOCALAPPDATA']!,
              'MinecraftToSpeech',
              'current',
              'data',
              'flutter_assets',
            );
      final String serverPath =
          p.join(workingDir, 'python-modules', 'dist', 'tts_server.exe');

      await Process.run(
        'PowerShell.exe',
        [
          'Get-Process',
          '|',
          'Where-Object',
          '{',
          '\$_.Path -eq "$serverPath"',
          '}',
          '|',
          'Stop-Process',
          '-Force',
        ],
      );

      _process = await Process.start(
        serverPath,
        ['--port', _port.toString()],
      );

      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:$_port'),
      );

      await clear();
    }

    unawaited(init());
  }

  static const _port = 53827;

  WebSocketChannel? _channel;
  Process? _process;

  @override
  Future<void> speak(String message) async {
    // Send message to tts_server
    await _channel?.ready;
    _channel?.sink.add('${_TtsServerCodes.msg} $message');
  }

  @override
  Future<void> clear() async {
    await _channel?.ready;
    _channel?.sink.add(_TtsServerCodes.clear.toString());
  }

  @override
  Future<void> destroy() async {
    await _channel!.ready;
    _channel!.sink.add(_TtsServerCodes.exit.toString());
    _process?.kill();
  }
}

enum _TtsServerCodes {
  msg,
  clear,
  exit;

  @override
  String toString() {
    switch (this) {
      case _TtsServerCodes.msg:
        return 'MSG';
      case _TtsServerCodes.clear:
        return 'CLR';
      case _TtsServerCodes.exit:
        return 'EXT';
    }
  }
}
