import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../setup/toaster.dart';

/// Blacklist certain phrases from being read.
class LogBlacklist {
  static final Box _blacklistBox = Hive.box<BlacklistItem>(name: 'blacklist');

  /// A filter for the blaclist items. If a message has a hit with any of the
  /// blacklist items, it will be filtered out.
  static bool filter(
    String message, {
    required BlacklistStream blacklistStream,
  }) {
    for (final BlacklistItem item
        in _blacklistBox.getRange(0, _blacklistBox.length)) {
      if (item.match(message, blacklistStream)) {
        return false;
      }
    }

    return true;
  }

  /// Add a phrase to the blacklist.
  static void add(
    String phrase, {
    BlacklistMatch blacklistMatch = BlacklistMatch.exact,
    Set<BlacklistStream> blacklistStreams = const {
      BlacklistStream.tts,
      BlacklistStream.discord,
      BlacklistStream.process,
    },
  }) {
    final item = BlacklistItem(
      phrase,
      blacklistMatch: blacklistMatch,
      blacklistStreams: blacklistStreams,
    );

    if (_blacklistBox.getRange(0, _blacklistBox.length).contains(item)) {
      Toaster.showToast('Already in blacklist.');
      return;
    }

    _blacklistBox.add(item);
  }
}

/// One item in the blacklist.
@immutable
class BlacklistItem {
  /// One item in the blacklist.
  const BlacklistItem(
    this.phrase, {
    this.blacklistMatch = BlacklistMatch.exact,
    this.blacklistStreams = const {
      BlacklistStream.tts,
      BlacklistStream.discord,
      BlacklistStream.process,
    },
  });

  /// Create a blacklist item from a json object.
  BlacklistItem.fromJson(Map<String, dynamic> json)
      : phrase = json['phrase'] as String,
        blacklistMatch = BlacklistMatch.values[json['blacklistMatch'] as int],
        blacklistStreams =
            (jsonDecode(json['blacklistStream']) as List<dynamic>)
                .map((dynamic stream) => BlacklistStream.values[stream as int])
                .toSet();

  /// The phrase to blacklist.
  final String phrase;

  /// The type of blacklist item.
  final BlacklistMatch blacklistMatch;

  /// What streams to filter from
  final Set<BlacklistStream> blacklistStreams;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is BlacklistItem &&
        other.phrase == phrase &&
        other.blacklistMatch == blacklistMatch &&
        other.blacklistStreams == blacklistStreams;
  }

  @override
  int get hashCode => Object.hash(phrase, blacklistMatch, blacklistStreams);

  @override
  String toString() =>
      'BlacklistItem(phrase: $phrase, blacklistMatch: $blacklistMatch, '
      'blacklistStream: $blacklistStreams)';

  /// Convert the blacklist item to a json object.
  Map<String, dynamic> toJson() => {
        'phrase': phrase,
        'blacklistMatch': blacklistMatch.index,
        'blacklistStream': jsonEncode(blacklistStreams.toList()),
      };

  /// Check if the message matches the blacklist item.
  bool match(String message, BlacklistStream stream) {
    if (!blacklistStreams.contains(stream)) {
      return false;
    }

    final String lowerMessage = message.toLowerCase();
    final String lowerPhrase = phrase.toLowerCase();

    switch (blacklistMatch) {
      case BlacklistMatch.exact:
        return lowerMessage == lowerPhrase;
      case BlacklistMatch.startsWith:
        return lowerMessage.startsWith(lowerPhrase);
      case BlacklistMatch.endsWith:
        return lowerMessage.endsWith(lowerPhrase);
      case BlacklistMatch.contains:
        return lowerMessage.contains(lowerPhrase);
    }
  }
}

/// The type of blacklist item.
enum BlacklistMatch {
  /// An exact phrase match.
  exact,

  /// A phrase that starts with the given text.
  startsWith,

  /// A phrase that ends with the given text.
  endsWith,

  /// A phrase that contains the given text.
  contains,
}

/// What streams to filter from
enum BlacklistStream {
  /// Blacklist from the tts stream.
  tts,

  /// Blacklist from the discord stream.
  discord,

  /// Blacklist from the process stream.
  process;

  /// All blacklist streams.
  static Set<BlacklistStream> get all =>
      <BlacklistStream>{tts, discord, process};

  /// Convert the blacklist stream to a json object.
  int toJson() => index;
}
