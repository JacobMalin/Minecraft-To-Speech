import 'package:flutter/material.dart';

/// A class for setting up the application theme.
class ThemeSetup {
  static const _seedColor = Color(0x00204969);

  static ThemeData _baseTheme(Brightness brightness) {
    const buttonStyle = ButtonStyle(
      splashFactory: NoSplash.splashFactory,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      splashFactory: NoSplash.splashFactory,
      textButtonTheme: TextButtonThemeData(
        style: buttonStyle.copyWith(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
      menuButtonTheme: const MenuButtonThemeData(style: buttonStyle),
      filledButtonTheme: const FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: const ElevatedButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: const OutlinedButtonThemeData(style: buttonStyle),
      segmentedButtonTheme: const SegmentedButtonThemeData(style: buttonStyle),
      buttonTheme: const ButtonThemeData(splashColor: Colors.transparent),
      toggleButtonsTheme: ToggleButtonsThemeData(
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 2,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme:
          DividerThemeData(color: colorScheme.surfaceContainerHighest),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(5),
        ),
        textStyle: TextStyle(color: colorScheme.onSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        menuPadding: EdgeInsets.zero,
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
        overlayColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 10),
      ),
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
    required this.enabledWarning,
    required this.disabled,
    required this.disabledHover,
    required this.disableWarning,
    required this.warning,
  });

  /// The light theme of the instance colors.
  const InstanceTheme.light()
      : enabled = const Color.fromARGB(255, 111, 200, 114),
        enabledHover = const Color.fromARGB(21, 0, 0, 0),
        enabledWarning = const Color.fromARGB(255, 206, 193, 68),
        disabled = const Color.fromARGB(255, 253, 96, 84),
        disabledHover = const Color.fromARGB(21, 0, 0, 0),
        disableWarning = const Color.fromARGB(255, 232, 168, 72),
        warning = const Color.fromARGB(255, 255, 165, 0);

  /// The dark theme of the instance colors.
  const InstanceTheme.dark()
      : enabled = const Color.fromARGB(255, 52, 156, 26),
        enabledHover = const Color.fromARGB(21, 0, 0, 0),
        enabledWarning = const Color.fromARGB(255, 187, 170, 0),
        disabled = const Color.fromARGB(255, 156, 28, 19),
        disabledHover = const Color.fromARGB(21, 0, 0, 0),
        disableWarning = const Color.fromARGB(255, 197, 123, 14),
        warning = const Color.fromARGB(255, 197, 123, 14);

  /// The color for enabled instances. Hover and warning colors are also
  /// defined.
  final Color enabled, enabledHover, enabledWarning;

  /// The color for disabled instances. Hover and warning colors are also
  /// defined.
  final Color disabled, disabledHover, disableWarning;

  /// The color for broken instances.
  final Color warning;

  @override
  InstanceTheme copyWith({
    Color? enabled,
    Color? enabledHover,
    Color? enabledWarning,
    Color? disabled,
    Color? disabledHover,
    Color? disableWarning,
    Color? warning,
  }) =>
      InstanceTheme(
        enabled: enabled ?? this.enabled,
        enabledHover: enabledHover ?? this.enabledHover,
        enabledWarning: enabledWarning ?? this.enabledWarning,
        disabled: disabled ?? this.disabled,
        disabledHover: disabledHover ?? this.disabledHover,
        disableWarning: disableWarning ?? this.disableWarning,
        warning: warning ?? this.warning,
      );

  @override
  InstanceTheme lerp(ThemeExtension<InstanceTheme>? other, double t) {
    if (other is! InstanceTheme) return this;
    return InstanceTheme(
      enabled: Color.lerp(enabled, other.enabled, t)!,
      enabledHover: Color.lerp(enabledHover, other.enabledHover, t)!,
      enabledWarning: Color.lerp(enabledWarning, other.enabledWarning, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      disabledHover: Color.lerp(disabledHover, other.disabledHover, t)!,
      disableWarning: Color.lerp(disableWarning, other.disableWarning, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
