import 'package:flutter/material.dart';

/// A class for setting up the application theme.
class ThemeSetup {
  static const _seedColor = Color(0x00204969);

  static const _buttonStyle =
      ButtonStyle(splashFactory: NoSplash.splashFactory);

  static ThemeData _baseTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      splashFactory: NoSplash.splashFactory,
      elevatedButtonTheme: const ElevatedButtonThemeData(style: _buttonStyle),
      textButtonTheme: const TextButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: const OutlinedButtonThemeData(style: _buttonStyle),
      iconButtonTheme: const IconButtonThemeData(style: _buttonStyle),
    );
  }

  /// The bright theme.
  static final ThemeData brightTheme = _baseTheme(Brightness.light).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const InstanceTheme.light(),
    ],
  );

  /// The dark theme.
  static final ThemeData darkTheme = _baseTheme(Brightness.dark).copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const InstanceTheme.dark(),
    ],
  );
}

/// The theme used for instances. Red for disabled, green for enabled.
class InstanceTheme extends ThemeExtension<InstanceTheme> {
  /// The theme used for instances. Red for disabled, green for enabled.
  const InstanceTheme({
    required this.enabled,
    required this.enabledHover,
    required this.enabledSelected,
    required this.disabled,
    required this.disabledHover,
    required this.disableSelected,
  });

  /// The light theme of the instance colors.
  const InstanceTheme.light()
      : enabled = const Color.fromARGB(255, 111, 200, 114),
        enabledHover = const Color.fromARGB(21, 0, 0, 0),
        enabledSelected = const Color.fromARGB(255, 111, 200, 114),
        disabled = const Color.fromARGB(255, 253, 96, 84),
        disabledHover = const Color.fromARGB(21, 0, 0, 0),
        disableSelected = const Color.fromARGB(255, 253, 96, 84);

  /// The dark theme of the instance colors.
  const InstanceTheme.dark()
      : enabled = const Color.fromARGB(255, 17, 159, 19),
        enabledHover = const Color.fromARGB(21, 0, 0, 0),
        enabledSelected = const Color.fromARGB(255, 27, 49, 27),
        disabled = const Color.fromARGB(255, 156, 28, 19),
        disabledHover = const Color.fromARGB(21, 0, 0, 0),
        disableSelected = const Color.fromARGB(255, 72, 30, 27);

  /// The color for enabled instances. Hover and selected colors are also
  /// defined.
  final Color enabled, enabledHover, enabledSelected;

  /// The color for disabled instances. Hover and selected colors are also
  /// defined.
  final Color disabled, disabledHover, disableSelected;

  @override
  InstanceTheme copyWith({
    Color? enabled,
    Color? enabledHover,
    Color? enabledSelected,
    Color? disabled,
    Color? disabledHover,
    Color? disableSelected,
  }) =>
      InstanceTheme(
        enabled: enabled ?? this.enabled,
        enabledHover: enabledHover ?? this.enabledHover,
        enabledSelected: enabledSelected ?? this.enabledSelected,
        disabled: disabled ?? this.disabled,
        disabledHover: disabledHover ?? this.disabledHover,
        disableSelected: disableSelected ?? this.disableSelected,
      );

  @override
  InstanceTheme lerp(ThemeExtension<InstanceTheme>? other, double t) {
    if (other is! InstanceTheme) return this;
    return InstanceTheme(
      enabled: Color.lerp(enabled, other.enabled, t)!,
      enabledHover: Color.lerp(enabledHover, other.enabledHover, t)!,
      enabledSelected: Color.lerp(enabledSelected, other.enabledSelected, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      disabledHover: Color.lerp(disabledHover, other.disabledHover, t)!,
      disableSelected: Color.lerp(disableSelected, other.disableSelected, t)!,
    );
  }
}
