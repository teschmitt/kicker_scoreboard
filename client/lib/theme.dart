import 'package:flutter/material.dart';

const _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF7C5800),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFFDEA6),
  onPrimaryContainer: Color(0xFF271900),
  secondary: Color(0xFF006A69),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFF6FF7F5),
  onSecondaryContainer: Color(0xFF002020),
  tertiary: Color(0xFF6D4EA1),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFECDCFF),
  onTertiaryContainer: Color(0xFF270057),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  background: Color(0xFFFFFBFF),
  onBackground: Color(0xFF24005A),
  surface: Color(0xFFFFFBFF),
  onSurface: Color(0xFF24005A),
  surfaceVariant: Color(0xFFEEE1CF),
  onSurfaceVariant: Color(0xFF4E4639),
  outline: Color(0xFF807667),
  onInverseSurface: Color(0xFFF6EDFF),
  inverseSurface: Color(0xFF3A1D71),
  inversePrimary: Color(0xFFF7BD48),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF7C5800),
  outlineVariant: Color(0xFFD1C5B4),
  scrim: Color(0xFF000000),
);

const _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFF7BD48),
  onPrimary: Color(0xFF412D00),
  primaryContainer: Color(0xFF5E4200),
  onPrimaryContainer: Color(0xFFFFDEA6),
  secondary: Color(0xFF4DDAD8),
  onSecondary: Color(0xFF003736),
  secondaryContainer: Color(0xFF00504F),
  onSecondaryContainer: Color(0xFF6FF7F5),
  tertiary: Color(0xFFD5BAFF),
  onTertiary: Color(0xFF3D1C6F),
  tertiaryContainer: Color(0xFF553587),
  onTertiaryContainer: Color(0xFFECDCFF),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  background: Color(0xFF24005A),
  onBackground: Color(0xFFEADDFF),
  surface: Color(0xFF24005A),
  onSurface: Color(0xFFEADDFF),
  surfaceVariant: Color(0xFF4E4639),
  onSurfaceVariant: Color(0xFFD1C5B4),
  outline: Color(0xFF9A8F80),
  onInverseSurface: Color(0xFF24005A),
  inverseSurface: Color(0xFFEADDFF),
  inversePrimary: Color(0xFF7C5800),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFF7BD48),
  outlineVariant: Color(0xFF4E4639),
  scrim: Color(0xFF000000),
);

class ScoreboardTheme {
  const ScoreboardTheme._();

  static final ThemeData dark =
      ThemeData.from(colorScheme: _darkColorScheme, useMaterial3: true, textTheme: _textTheme);

  static final ThemeData light =
      ThemeData.from(colorScheme: _lightColorScheme, useMaterial3: true, textTheme: _textTheme);

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.w700,
      fontSize: 128,
    ),
  );
}
