import 'package:flutter/material.dart';

/// Semantic colour tokens. Widgets read these through `context.colors`
/// instead of using `Colors.*` literals, so light and dark stay in sync.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color accentSubtle;
  final Color onAccent;
  final Color success;
  final Color successSubtle;
  final Color danger;
  final Color dangerSubtle;
  final Color warning;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentSubtle,
    required this.onAccent,
    required this.success,
    required this.successSubtle,
    required this.danger,
    required this.dangerSubtle,
    required this.warning,
  });

  static const light = AppColors(
    bg: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4F4F5),
    border: Color(0xFFE4E4E7),
    borderStrong: Color(0xFFD4D4D8),
    textPrimary: Color(0xFF18181B),
    textMuted: Color(0xFF71717A),
    accent: Color(0xFF4F46E5),
    accentSubtle: Color(0xFFEEF2FF),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF16A34A),
    successSubtle: Color(0xFFF0FDF4),
    danger: Color(0xFFDC2626),
    dangerSubtle: Color(0xFFFEF2F2),
    warning: Color(0xFFD97706),
  );

  static const dark = AppColors(
    bg: Color(0xFF09090B),
    surface: Color(0xFF18181B),
    surfaceMuted: Color(0xFF1F1F23),
    border: Color(0xFF27272A),
    borderStrong: Color(0xFF3F3F46),
    textPrimary: Color(0xFFFAFAFA),
    textMuted: Color(0xFFA1A1AA),
    accent: Color(0xFF818CF8),
    accentSubtle: Color(0xFF1E1B4B),
    onAccent: Color(0xFF09090B),
    success: Color(0xFF4ADE80),
    successSubtle: Color(0xFF052E16),
    danger: Color(0xFFF87171),
    dangerSubtle: Color(0xFF450A0A),
    warning: Color(0xFFFBBF24),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textMuted,
    Color? accent,
    Color? accentSubtle,
    Color? onAccent,
    Color? success,
    Color? successSubtle,
    Color? danger,
    Color? dangerSubtle,
    Color? warning,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      danger: danger ?? this.danger,
      dangerSubtle: dangerSubtle ?? this.dangerSubtle,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSubtle: Color.lerp(dangerSubtle, other.dangerSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
