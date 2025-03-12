import 'dart:async';
import 'dart:collection';

import 'package:flutter_tts/flutter_tts.dart';

/// Queue for TTS (Text to Speech) messages.
class TtsQueue {
  /// Get the singleton instance of the TTS queue.
  factory TtsQueue() => _instance;

  // Constructor must be private
  TtsQueue._() {
    Future<void> configureTts() async {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(1);
      await _flutterTts.setVolume(1);

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

    unawaited(configureTts());
  }

  /// Singleton instance of the TTS queue.
  // ignore: unused_field
  static final _instance = TtsQueue._();

  final _flutterTts = FlutterTts();
  final Queue _queue = Queue();
  var _isSpeaking = false;

  /// Add a message to the TTS queue.
  void speak(String message) {
    _queue.add(message);
  }

  /// Clear the TTS queue.
  Future<void> clear() async {
    _queue.clear();
    await _flutterTts.stop();
    _isSpeaking = false;
  }
}
