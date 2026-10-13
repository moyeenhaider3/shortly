import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale tuned for desktop density (14px base, like Dub).
/// Inter for UI, JetBrains Mono for short links, codes and IPs.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle body;
  final TextStyle small;
  final TextStyle caption;
  final TextStyle overline;
  final TextStyle mono;
  final TextStyle metric;

  const AppTypography({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body,
    required this.small,
    required this.caption,
    required this.overline,
    required this.mono,
    required this.metric,
  });

  static const String sans = 'Inter';
  static const String monoFamily = 'JetBrainsMono';

  factory AppTypography.from(AppColors c) {
    const tabular = [FontFeature.tabularFigures()];
    return AppTypography(
      display: TextStyle(
        fontFamily: sans,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: c.textPrimary,
      ),
      h1: TextStyle(
        fontFamily: sans,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: c.textPrimary,
      ),
      h2: TextStyle(
        fontFamily: sans,
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: c.textPrimary,
      ),
      h3: TextStyle(fontFamily: sans, fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: c.textPrimary),
      body: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: c.textPrimary,
      ),
      small: TextStyle(
        fontFamily: sans,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: c.textMuted,
      ),
      caption: TextStyle(
        fontFamily: sans,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: c.textMuted,
        fontFeatures: tabular,
      ),
      overline: TextStyle(
        fontFamily: sans,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: c.textMuted,
      ),
      mono: TextStyle(
        fontFamily: monoFamily,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      metric: TextStyle(
        fontFamily: sans,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: c.textPrimary,
        fontFeatures: tabular,
      ),
    );
  }

  /// Material text theme mapped onto the scale so stock widgets match.
  TextTheme toTextTheme() => TextTheme(
    displaySmall: display,
    headlineMedium: h1,
    headlineSmall: h1,
    titleLarge: h2,
    titleMedium: h3,
    titleSmall: h3,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: small,
    labelLarge: body.copyWith(fontWeight: FontWeight.w500),
    labelMedium: caption,
    labelSmall: caption,
  );

  @override
  AppTypography copyWith({
    TextStyle? display,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? body,
    TextStyle? small,
    TextStyle? caption,
    TextStyle? overline,
    TextStyle? mono,
    TextStyle? metric,
  }) {
    return AppTypography(
      display: display ?? this.display,
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      body: body ?? this.body,
      small: small ?? this.small,
      caption: caption ?? this.caption,
      overline: overline ?? this.overline,
      mono: mono ?? this.mono,
      metric: metric ?? this.metric,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      small: TextStyle.lerp(small, other.small, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
      metric: TextStyle.lerp(metric, other.metric, t)!,
    );
  }
}
