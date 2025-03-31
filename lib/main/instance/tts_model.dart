import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
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

  /// Set the voice for TTS messages.
  String get voice => _strategy.voice;

  /// Set the voice for TTS messages.
  Future<void> setVoice(String voice) async => _strategy.setVoice(voice);

  /// Get the list of available voices for TTS messages.
  Future<Map<String, String>> getVoices() async => _strategy.getVoices();

  /// The volume of the TTS messages.
  double get volume => _strategy.volume;

  /// The volume of the TTS messages.
  Future<void> setVolume(double value) async => _strategy.setVolume(value);

  /// The speech rate of the TTS messages.
  double get rate => _strategy.rate;

  /// The speech rate of the TTS messages.
  Future<void> setRate(double value) async => _strategy.setRate(value);

  /// The speech rate of the TTS messages as a string.
  String get rateAsString => _strategy.rateAsString;

  /// The abbreviation of the unit for speech rate of the TTS messages.
  String formatRate(double value) => _strategy.formatRate(value);

  /// The minimum acceptable speech rate for TTS messages.
  double get rateMin => _strategy.rateMin;

  /// The maximum acceptable speech rate for TTS messages.
  double get rateMax => _strategy.rateMax;

  /// The step size for the speech rate.
  double get rateStep => _strategy.rateStep;

  /// Add a message to the TTS queue.
  Future<void> speak(String message) async => _strategy.speak(message);

  /// Clear the TTS queue.
  Future<void> clear() async => _strategy.clear();

  /// Clean up the TTS queue.
  Future<void> destroy() async => _strategy.destroy();
}

/// Strategy for speaking TTS messages.
abstract class _TtsStrategy {
  /// The voice for TTS messages.
  String get voice;
  Future<void> setVoice(String voice);
  Future<Map<String, String>> getVoices();

  /// The volume for TTS messages.
  double get volume;
  Future<void> setVolume(double value);

  /// The speech rate for TTS messages.
  double get rate;
  Future<void> setRate(double value);

  /// The speech rate of the TTS messages as a string.
  String get rateAsString;

  /// The abbreviation of the unit for speech rate of the TTS messages.
  String formatRate(double value);

  // The minimum acceptable rate for TTS messages.
  double get rateMin;

  /// The maximum acceptable rate for TTS messages.
  double get rateMax;

  /// The step size for the speech rate.
  double get rateStep;

  /// Speak a message.
  Future<void> speak(String message);

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

      await setVolume(_box.volume);
      await setRate(_box.rate);
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

  final _box = _TtsBox(
    'flutterTts',
    defaultVoice:
        r'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_EN-US_DAVID_11.0',
    defaultVolume: 1,
    defaultRate: 1,
  );
  final _flutterTts = FlutterTts();
  final Queue _queue = Queue<String>();
  var _isSpeaking = false;

  @override
  String get voice => '';
  @override
  Future<void> setVoice(String voice) async {}
  @override
  Future<Map<String, String>> getVoices() async => {};

  @override
  double get volume => _box.volume;
  @override
  Future<void> setVolume(double volume) async {
    _box.volume = volume;
    await _flutterTts.setVolume(volume);
  }

  @override
  double get rate => _box.rate;
  @override
  Future<void> setRate(double rate) async {
    _box.rate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  String get rateAsString => rate.toStringAsFixed(2);
  @override
  String formatRate(double value) => value.toStringAsFixed(2);

  @override
  double get rateMin => 0;
  @override
  double get rateMax => 1;
  @override
  double get rateStep => 0.1;

  @override
  Future<void> speak(String message) async => _queue.add(message);

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

      if (kDebugMode) {
        // Print is being avoided
        // ignore: avoid_print
        unawaited(_process!.stdout.forEach((msg) => print(utf8.decode(msg))));
        // Print is being avoided
        // ignore: avoid_print
        unawaited(_process!.stderr.forEach((msg) => print(utf8.decode(msg))));

        _channel?.stream.listen(
          // Print is being avoided
          // ignore: avoid_print
          (dynamic message) => print(message as String),
        );
      }

      await setVoice(_box.voice);
      await setVolume(_box.volume);
      await setRate(_box.rate);
    }

    unawaited(init());
  }

  static const _port = 53827;

  late final _box = _TtsBox(
    'sapi5',
    defaultVoice: '',
    defaultVolume: 1,
    defaultRate: 150,
  );

  WebSocketChannel? _channel;
  Process? _process;

  @override
  String get voice => _box.voice;
  @override
  Future<void> setVoice(String voice) async {
    await _channel?.ready;
    _channel?.sink.add('${_TtsServerCodes.voice} $voice');
    final message = await _channel!.stream.first as String;
    _box.voice = message.split('Voice set to ')[1];
  }

  @override
  Future<Map<String, String>> getVoices() async {
    await _channel?.ready;
    _channel?.sink.add('${_TtsServerCodes.getVoices}');
    final message = await _channel!.stream.first as String;
    return jsonDecode(message.split('Voices: ')[1]);
  }

  @override
  double get volume => _box.volume;
  @override
  Future<void> setVolume(double volume) async {
    _box.volume = volume;
    await _channel?.ready;
    _channel?.sink.add('${_TtsServerCodes.volume} $volume');
  }

  @override
  double get rate => _box.rate;
  @override
  Future<void> setRate(double rate) async {
    _box.rate = rate;
    await _channel?.ready;
    _channel?.sink.add('${_TtsServerCodes.rate} $rate');
  }

  @override
  String get rateAsString => '${rate.toInt()} words per minute';
  @override
  String formatRate(double value) => '${value.toInt()} wpm';

  @override
  double get rateMin => 50;
  @override
  double get rateMax => 500;
  @override
  double get rateStep => 10;

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
  voice,
  getVoices,
  volume,
  rate,
  exit;

  @override
  String toString() {
    switch (this) {
      case _TtsServerCodes.msg:
        return 'MSG';
      case _TtsServerCodes.clear:
        return 'CLR';
      case _TtsServerCodes.voice:
        return 'VOC';
      case _TtsServerCodes.getVoices:
        return 'GVC';
      case _TtsServerCodes.volume:
        return 'VOL';
      case _TtsServerCodes.rate:
        return 'RTE';
      case _TtsServerCodes.exit:
        return 'EXT';
    }
  }
}

/// A box for persistent TTS settings.
class _TtsBox {
  _TtsBox(
    String identifier, {
    required String defaultVoice,
    required double defaultVolume,
    required double defaultRate,
  })  : _identifier = identifier,
        _defaultVoice = defaultVoice,
        _defaultVolume = defaultVolume,
        _defaultRate = defaultRate;

  static final Box _ttsBox = Hive.box(name: 'tts');

  final String _identifier;
  final String _defaultVoice;
  final double _defaultVolume;
  final double _defaultRate;

  /// The id for the voice of the TTS messages.
  String get voice => _ttsBox['$_identifier-voice'] ?? _defaultVoice;
  set voice(String voice) => _ttsBox['$_identifier-voice'] = voice;

  /// The volume of the TTS messages.
  double get volume => _ttsBox['$_identifier-volume'] ?? _defaultVolume;
  set volume(double volume) => _ttsBox['$_identifier-volume'] = volume;

  /// The speech rate of the TTS messages.
  double get rate => _ttsBox['$_identifier-rate'] ?? _defaultRate;
  set rate(double rate) => _ttsBox['$_identifier-rate'] = rate;
}
