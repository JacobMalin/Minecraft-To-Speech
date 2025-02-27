import 'package:flutter/material.dart';

class ThemeSetup {
  static final _seedColor = const Color(0x00204969);

  static final _buttonStyle =
      const ButtonStyle(splashFactory: NoSplash.splashFactory);

  static ThemeData _baseTheme(final Brightness brightness) {
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

  static final ThemeData brightTheme = _baseTheme(Brightness.light).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const InstanceTheme.light(),
    ],
  );

  static final ThemeData darkTheme = _baseTheme(Brightness.dark).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const InstanceTheme.dark(),
    ],
  );
}

class InstanceTheme extends ThemeExtension<InstanceTheme> {
  final Color green, red;
  final Color greenHover, redHover;
  final Color greenSelected, redSelected;

  const InstanceTheme({
    required this.green,
    required this.red,
    required this.greenHover,
    required this.redHover,
    required this.greenSelected,
    required this.redSelected,
  });
  const InstanceTheme.light()
      : green = const Color.fromARGB(255, 111, 200, 114),
        red = const Color.fromARGB(255, 253, 96, 84),
        greenHover = const Color.fromARGB(21, 0, 0, 0),
        redHover = const Color.fromARGB(21, 0, 0, 0),
        greenSelected = const Color.fromARGB(255, 111, 200, 114),
        redSelected = const Color.fromARGB(255, 253, 96, 84);
  const InstanceTheme.dark()
      : green = const Color.fromARGB(255, 17, 159, 19),
        red = const Color.fromARGB(255, 156, 28, 19),
        greenHover = const Color.fromARGB(21, 0, 0, 0),
        redHover = const Color.fromARGB(21, 0, 0, 0),
        greenSelected = const Color.fromARGB(255, 27, 49, 27),
        redSelected = const Color.fromARGB(255, 72, 30, 27);

  @override
  InstanceTheme copyWith(
      {final Color? green,
      final Color? red,
      final Color? greenHover,
      final Color? redHover,
      final Color? greenSelected,
      final Color? redSelected}) {
    return InstanceTheme(
      green: green ?? this.green,
      red: red ?? this.red,
      greenHover: greenHover ?? this.greenHover,
      redHover: redHover ?? this.redHover,
      greenSelected: greenSelected ?? this.greenSelected,
      redSelected: redSelected ?? this.redSelected,
    );
  }

  @override
  InstanceTheme lerp(
      final ThemeExtension<InstanceTheme>? other, final double t) {
    if (other is! InstanceTheme) return this;
    return InstanceTheme(
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      greenHover: Color.lerp(greenHover, other.greenHover, t)!,
      redHover: Color.lerp(redHover, other.redHover, t)!,
      greenSelected: Color.lerp(greenSelected, other.greenSelected, t)!,
      redSelected: Color.lerp(redSelected, other.redSelected, t)!,
    );
  }
}
