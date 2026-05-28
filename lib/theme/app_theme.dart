import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'SF Pro Display';
  static const List<String> fontFallback = [
    'SF Pro Text',
    'SF UI Display',
    'SF UI Text',
    '-apple-system',
    'Roboto',
    'Arial',
  ];

  static ThemeData light() {
    const palette = AuthPalette(
      green: Color(0xFF10B981),
      greenDark: Color(0xFF069464),
      text: Color(0xFF172033),
      mutedText: Color(0xFFA0ABBD),
      fieldBorder: Color(0xFFE4E4E4),
      fieldFill: Color(0xFFFBFBFB),
      screen: Color(0xFFFFFFFF),
      inactiveDot: Color(0xFFE3E3E3),
      softGreen: Color(0xFFEAF8F2),
      error: Color(0xFFE5484D),
      buttonShadow: Color(0x3310B981),
      splashTop: Color(0xFF00553D),
      splashBottom: Color(0xFF2BCF9A),
    );

    return _theme(Brightness.light, palette);
  }

  static ThemeData dark() {
    const palette = AuthPalette(
      green: Color(0xFF33D69F),
      greenDark: Color(0xFF0CA875),
      text: Color(0xFFF7FAFC),
      mutedText: Color(0xFF93A2B7),
      fieldBorder: Color(0xFF2B3441),
      fieldFill: Color(0xFF151B22),
      screen: Color(0xFF0D1117),
      inactiveDot: Color(0xFF343C47),
      softGreen: Color(0xFF102F24),
      error: Color(0xFFFF6B6B),
      buttonShadow: Color(0x4033D69F),
      splashTop: Color(0xFF002C23),
      splashBottom: Color(0xFF008F69),
    );

    return _theme(Brightness.dark, palette);
  }

  static ThemeData _theme(Brightness brightness, AuthPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.green,
      brightness: brightness,
      primary: palette.green,
      surface: palette.screen,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.screen,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      textTheme: Typography.material2021().black.apply(
        bodyColor: palette.text,
        displayColor: palette.text,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
      ),
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.greenDark,
        selectionColor: palette.green.withValues(alpha: 0.18),
        selectionHandleColor: palette.green,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}

@immutable
class AuthPalette extends ThemeExtension<AuthPalette> {
  const AuthPalette({
    required this.green,
    required this.greenDark,
    required this.text,
    required this.mutedText,
    required this.fieldBorder,
    required this.fieldFill,
    required this.screen,
    required this.inactiveDot,
    required this.softGreen,
    required this.error,
    required this.buttonShadow,
    required this.splashTop,
    required this.splashBottom,
  });

  final Color green;
  final Color greenDark;
  final Color text;
  final Color mutedText;
  final Color fieldBorder;
  final Color fieldFill;
  final Color screen;
  final Color inactiveDot;
  final Color softGreen;
  final Color error;
  final Color buttonShadow;
  final Color splashTop;
  final Color splashBottom;

  @override
  AuthPalette copyWith({
    Color? green,
    Color? greenDark,
    Color? text,
    Color? mutedText,
    Color? fieldBorder,
    Color? fieldFill,
    Color? screen,
    Color? inactiveDot,
    Color? softGreen,
    Color? error,
    Color? buttonShadow,
    Color? splashTop,
    Color? splashBottom,
  }) {
    return AuthPalette(
      green: green ?? this.green,
      greenDark: greenDark ?? this.greenDark,
      text: text ?? this.text,
      mutedText: mutedText ?? this.mutedText,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      fieldFill: fieldFill ?? this.fieldFill,
      screen: screen ?? this.screen,
      inactiveDot: inactiveDot ?? this.inactiveDot,
      softGreen: softGreen ?? this.softGreen,
      error: error ?? this.error,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      splashTop: splashTop ?? this.splashTop,
      splashBottom: splashBottom ?? this.splashBottom,
    );
  }

  @override
  AuthPalette lerp(ThemeExtension<AuthPalette>? other, double t) {
    if (other is! AuthPalette) {
      return this;
    }

    return AuthPalette(
      green: Color.lerp(green, other.green, t)!,
      greenDark: Color.lerp(greenDark, other.greenDark, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      screen: Color.lerp(screen, other.screen, t)!,
      inactiveDot: Color.lerp(inactiveDot, other.inactiveDot, t)!,
      softGreen: Color.lerp(softGreen, other.softGreen, t)!,
      error: Color.lerp(error, other.error, t)!,
      buttonShadow: Color.lerp(buttonShadow, other.buttonShadow, t)!,
      splashTop: Color.lerp(splashTop, other.splashTop, t)!,
      splashBottom: Color.lerp(splashBottom, other.splashBottom, t)!,
    );
  }
}
