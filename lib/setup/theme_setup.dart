import 'package:flutter/material.dart';

class ThemeSetup {
  static final _seedColor = const Color(0x00204969);

  static final _buttonStyle = ButtonStyle(
    splashFactory: NoSplash.splashFactory
  );

  static ThemeData _baseTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      splashFactory: NoSplash.splashFactory,
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
      textButtonTheme: TextButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
      iconButtonTheme: IconButtonThemeData(style: _buttonStyle),
    );
  }

  static final brightTheme = _baseTheme(Brightness.light).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      FileTheme.light(),
    ],
  );

  static final darkTheme = _baseTheme(Brightness.dark).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      FileTheme.dark(),
    ],
  );
}

class FileTheme extends ThemeExtension<FileTheme> {
  final Color green, red;
  final Color greenHover, redHover;
  final Color greenSelected, redSelected;

  const FileTheme({
    required this.green,
    required this.red,
    required this.greenHover,
    required this.redHover,
    required this.greenSelected,
    required this.redSelected,
  });
  const FileTheme.light()
      : green = const Color.fromARGB(255, 111, 200, 114),
        red = const Color.fromARGB(255, 253, 96, 84),
        greenHover = const Color.fromARGB(21, 0, 0, 0),
        redHover = const Color.fromARGB(21, 0, 0, 0),
        greenSelected = const Color.fromARGB(255, 111, 200, 114),
        redSelected = const Color.fromARGB(255, 253, 96, 84);
  const FileTheme.dark()
      : green = const Color.fromARGB(255, 17, 159, 19),
        red = const Color.fromARGB(255, 156, 28, 19),
        greenHover = const Color.fromARGB(21, 0, 0, 0),
        redHover = const Color.fromARGB(21, 0, 0, 0),
        greenSelected = const Color.fromARGB(255, 27, 49, 27),
        redSelected = const Color.fromARGB(255, 72, 30, 27);

  @override
  FileTheme copyWith(
      {Color? green,
      Color? red,
      Color? greenHover,
      Color? redHover,
      Color? greenSelected,
      Color? redSelected}) {
    return FileTheme(
      green: green ?? this.green,
      red: red ?? this.red,
      greenHover: greenHover ?? this.greenHover,
      redHover: redHover ?? this.redHover,
      greenSelected: greenSelected ?? this.greenSelected,
      redSelected: redSelected ?? this.redSelected,
    );
  }

  @override
  FileTheme lerp(ThemeExtension<FileTheme>? other, double t) {
    if (other is! FileTheme) return this;
    return FileTheme(
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      greenHover: Color.lerp(greenHover, other.greenHover, t)!,
      redHover: Color.lerp(redHover, other.redHover, t)!,
      greenSelected: Color.lerp(greenSelected, other.greenSelected, t)!,
      redSelected: Color.lerp(redSelected, other.redSelected, t)!,
    );
  }
}
