import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../main/instance/log_filter.dart';
import '../setup/toaster.dart';
import '../setup/window_setup.dart';

/// Blacklist certain phrases from being read.
class BlacklistModel extends ChangeNotifier {
  /// Blacklist certain phrases from being read.
  BlacklistModel() {
    _blacklistBox.watch().listen((_) => notifyListeners());
  }

  static final Box _blacklistBox = Hive.box<BlacklistItem>(name: 'blacklist');

  static WindowManagerPlus? _window;

  /// Get if the blacklist is empty.
  bool get isEmpty => _blacklistBox.isEmpty;

  /// Get the length of the blacklist.
  int get length => _blacklistBox.length;

  /// Get an item from the blacklist.
  BlacklistItem operator [](int index) => _blacklistBox[index];

  /// Edit the blacklist.
  static Future<void> edit() async {
    final List<int> windows = await WindowManagerPlus.getAllWindowManagerIds();
    if (windows.contains(_window?.id)) {
      await WindowSetup.focusAndBringToFront(_window!.id);
    } else {
      _window = await WindowManagerPlus.createWindow([WindowType.blacklist]);
    }
  }

  /// A filter for the blaclist items. If a message has a hit with any of the
  /// blacklist items, it will be filtered out. Returns false if the filter is
  /// matched.
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

  /// If the filter matches any filters.Returns false if the filter is matched.
  static bool filterAny(
    String message,
  ) {
    for (final BlacklistItem item
        in _blacklistBox.getRange(0, _blacklistBox.length)) {
      if (item.matchAny(message)) {
        return false;
      }
    }

    return true;
  }

  /// Add a phrase to the blacklist. Returns sucess.
  bool add(
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
      return false;
    }

    _blacklistBox.add(item);

    return true;
  }

  /// Return if a phrase is already in the blacklist.
  static bool contains(
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

    return _blacklistBox.getRange(0, _blacklistBox.length).contains(item);
  }

  /// Modify blacklist items to allow a phrase in a stream. If the blacklist
  /// item only blocks the phrase in the given stream, it gets disabled.
  void modifyToAllow(
    String phrase,
    BlacklistStream stream,
  ) {
    for (int i = _blacklistBox.length - 1; i >= 0; i--) {
      final BlacklistItem item = _blacklistBox[i];
      if (item.match(phrase, stream)) {
        final Set<BlacklistStream> blacklistStreams = item.blacklistStreams
          ..remove(stream);

        updateWith(i, blacklistStreams: blacklistStreams);
      }
    }
  }

  /// Delete a blacklist item.
  void delete(int index) => _blacklistBox.deleteAt(index);

  /// Remove any blacklist items that block a given phrase from a stream.
  void deleteToAllow(
    String phrase,
    BlacklistStream stream,
  ) {
    for (int i = _blacklistBox.length - 1; i >= 0; i--) {
      final BlacklistItem item = _blacklistBox[i];
      if (item.match(phrase, stream)) _blacklistBox.deleteAt(i);
    }
  }

  /// Delete any blacklist items that block a given phrase.
  void deleteAny(String phrase) {
    for (int i = _blacklistBox.length - 1; i >= 0; i--) {
      final BlacklistItem item = _blacklistBox[i];
      if (item.matchAny(phrase)) _blacklistBox.deleteAt(i);
    }
  }

  /// Update a blacklist item.
  void updateWith(
    int index, {
    String? phrase,
    BlacklistMatch? blacklistMatch,
    Set<BlacklistStream>? blacklistStreams,
  }) {
    final BlacklistItem item = _blacklistBox[index];
    _blacklistBox[index] = item.copyWith(
      phrase: phrase,
      blacklistMatch: blacklistMatch,
      blacklistStreams: blacklistStreams,
    );
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
        setEquals(other.blacklistStreams, blacklistStreams);
  }

  @override
  int get hashCode => Object.hash(phrase, blacklistMatch, blacklistStreams);

  @override
  String toString() =>
      'BlacklistItem(phrase: "$phrase", ${blacklistMatch.name}, '
      '${blacklistStreams.map((stream) => stream.name)})';

  /// Copy a new blacklist item with the given values.
  BlacklistItem copyWith({
    String? phrase,
    BlacklistMatch? blacklistMatch,
    Set<BlacklistStream>? blacklistStreams,
  }) =>
      BlacklistItem(
        phrase ?? this.phrase,
        blacklistMatch: blacklistMatch ?? this.blacklistMatch,
        blacklistStreams: blacklistStreams ?? this.blacklistStreams,
      );

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

    return matchAny(message);
  }

  /// Check if the message matches the blacklist item with any stream.
  bool matchAny(String message) {
    if (blacklistStreams.isEmpty) return false;

    final String lowerMessage = message.toLowerCase().removeFormatTags();
    final String lowerPhrase = phrase.toLowerCase().removeFormatTags();

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

  /// Convert the blacklist stream to a json object.
  int toJson() => index;

  /// Get stream is blacklisted icon
  Widget get icon {
    switch (this) {
      case BlacklistStream.tts:
        return const Icon(Icons.speaker_notes_outlined);
      case BlacklistStream.discord:
        return const ImageIcon(
          AssetImage('assets/blacklist/discord.png'),
        );
      case BlacklistStream.process:
        return const ImageIcon(
          AssetImage('assets/blacklist/process.png'),
        );
    }
  }

  /// Get stream is blacklisted icon
  Widget get disabledIcon {
    switch (this) {
      case BlacklistStream.tts:
        return const Icon(Icons.speaker_notes_off_outlined);
      case BlacklistStream.discord:
        return const ImageIcon(
          AssetImage('assets/blacklist/no_discord.png'),
        );
      case BlacklistStream.process:
        return const Icon(Icons.no_sim_outlined);
    }
  }
}
