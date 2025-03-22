/// Path formatting utilities.
class PathFormatting {
  /// Non-breaking space. Used to prevent breaking but still have a space.
  static const nonBreakingSpace = '\u202f';

  /// Word joiner. Used to prevent breaking but without a space. Also called a
  /// zero-width non-breaking space.
  static const wordJoiner = '\u2060';

  /// Zero-width space. Used to break a string without a visible character.
  static const zeroWidthSpace = '\u200b';

  /// Makes spaces non-breaking and slashes breaking.
  static String breakBetter(String path) {
    return path
        .replaceAll(' ', nonBreakingSpace)
        .replaceAll(r'\', '\\$zeroWidthSpace');
  }

  /// Makes colon and space non-breaking.
  static String breakLess(String path) {
    return path
        .replaceFirst(':', ':$wordJoiner')
        .replaceAll(' ', nonBreakingSpace);
  }
}
