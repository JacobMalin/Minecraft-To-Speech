class FileFilter {
  static bool onlyChat(String line) {
    return line.contains("[CHAT]");
  }

  static String commonMap(String line) {
    return line.removeFormatTags();
  }

  static String uiMap(String line) {
    final String timeStamp = line.timeStamp();
    final String chatMessage = line.afterChat();
    return "$timeStamp $chatMessage";
  }

  static String ttsMap(String line) {
    final chatMessage = line.afterChat();

    final Match? match = RegExp(r'^<(.*?)> (.*)$').firstMatch(chatMessage);
    if (match == null) return chatMessage;

    final String? username = match.group(1);
    final String? message = match.group(2);

    return "$username says $message";
  }

  static String discordMap(String line) {
    return line.afterChat();
  }
}

extension ChatTransform on String {
  String afterChat() => split("[CHAT] ").last;
  String timeStamp() => RegExp(r'^\[.*?\]').stringMatch(this) ?? "";
  String removeFormatTags() => replaceAll(RegExp(r'§.'), '');
}
