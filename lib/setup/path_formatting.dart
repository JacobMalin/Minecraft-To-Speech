/// Path formatting utilities.
class PathFormatting {
  /// Makes spaces non-breaking and slashes breaking.
  static String breakBetter(String path) {
    return path.replaceAll(' ', '\u202f').replaceAll(r'\', '\\\u200b');
  }

  /// Makes colon and space non-breaking.
  static String breakLess(String path) {
    return path.replaceFirst(':', ':\u2060').replaceAll(' ', '\u202f');
  }
}
