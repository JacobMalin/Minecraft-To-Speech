/// A set of log processing filters.
class LogFilter {
  /// Filters out all lines that do not contain "[CHAT]".
  static bool onlyChat(String line) => line.contains('[CHAT]');

  /// Performes mapping that is common to all streams. This includes removing
  /// all minecraft formatting tags.
  static String commonMap(String line) => line.removeFormatTags();

  /// Maps the line to a format that is suitable for the UI. The format is
  /// "timeStamp chatMessage".
  static String uiMap(String line) {
    final String timeStamp = line.timeStamp();
    final String chatMessage = line.afterChat();
    return '$timeStamp $chatMessage';
  }

  /// Maps the line to a format that is suitable for TTS. The format is
  /// "username says message".
  static String ttsMap(String line) {
    final String chatMessage = line.afterChat();

    final Match? match = RegExp(r'^<(.*?)> (.*)$').firstMatch(chatMessage);
    if (match == null) return chatMessage;

    final String? username = match.group(1);
    final String? message = match.group(2);

    return '$username says $message';
  }

  /// Maps the line to a format that is suitable for Discord. This format is
  /// the most similar to minecraft chat.
  static String discordMap(String line) => line.afterChat();
}

/// Extension methods on strings for the chat processing.
extension ChatTransform on String {
  /// Returns the chat message after the "[CHAT]" tag.
  String afterChat() => split('[CHAT] ').last;

  /// Returns the timestamp of the chat message.
  String timeStamp() => RegExp(r'^\[.*?\]').stringMatch(this) ?? '';

  /// Removes all minecraft formatting tags from the string.
  String removeFormatTags() => replaceAll(RegExp('§.'), '');
}
