import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final type = AppTypography.from(c);
    final textTheme = type.toTextTheme();

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSubtle,
      onPrimaryContainer: c.accent,
      secondary: c.textPrimary,
      onSecondary: c.surface,
      error: c.danger,
      onError: c.onAccent,
      errorContainer: c.dangerSubtle,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.bg,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceMuted,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.borderStrong,
      outlineVariant: c.border,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.surface,
      shadow: const Color(0xFF000000),
      surfaceTint: const Color(0x00000000),
    );

    // Keyboard focus gets a visible accent ring; hover/press get a subtle tint.
    final focusRing = BorderSide(color: c.accent.withValues(alpha: 0.4), width: 2);
    WidgetStateProperty<Color?> overlay(Color base) => WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.pressed)) return base.withValues(alpha: 0.12);
      if (s.contains(WidgetState.hovered)) return base.withValues(alpha: 0.06);
      if (s.contains(WidgetState.focused)) return base.withValues(alpha: 0.08);
      return null;
    });

    // 44px on touch platforms; adaptive density trims 8px on desktop → 36px.
    const minButtonSize = Size(64, Layout.controlHeightTouch);
    const buttonShape = RoundedRectangleBorder(borderRadius: Radii.mdAll);
    final buttonText = type.body.copyWith(fontWeight: FontWeight.w500);
    const buttonPadding = EdgeInsets.symmetric(horizontal: Space.s4);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: Radii.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.sans,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.border,
      hoverColor: c.textPrimary.withValues(alpha: 0.04),
      focusColor: c.accent.withValues(alpha: 0.12),
      splashFactory: NoSplash.splashFactory,
      extensions: [c, type],
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.textMuted, size: 18),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: type.h3,
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s3),
        hintStyle: type.body.copyWith(color: c.textMuted),
        labelStyle: type.body.copyWith(color: c.textMuted),
        floatingLabelStyle: type.small.copyWith(color: c.accent),
        helperStyle: type.small,
        errorStyle: type.small.copyWith(color: c.danger),
        prefixIconColor: c.textMuted,
        suffixIconColor: c.textMuted,
        border: inputBorder(c.borderStrong),
        enabledBorder: inputBorder(c.borderStrong),
        focusedBorder: inputBorder(c.accent, 1.5),
        errorBorder: inputBorder(c.danger),
        focusedErrorBorder: inputBorder(c.danger, 1.5),
        disabledBorder: inputBorder(c.border),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minButtonSize),
          padding: const WidgetStatePropertyAll(buttonPadding),
          shape: const WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.accent.withValues(alpha: 0.4) : c.accent,
          ),
          foregroundColor: WidgetStatePropertyAll(c.onAccent),
          overlayColor: overlay(c.onAccent),
          side: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.focused) ? focusRing : null),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minButtonSize),
          padding: const WidgetStatePropertyAll(buttonPadding),
          shape: const WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          backgroundColor: WidgetStatePropertyAll(c.surface),
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          iconColor: WidgetStatePropertyAll(c.textMuted),
          overlayColor: overlay(c.textPrimary),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? focusRing : BorderSide(color: c.borderStrong),
          ),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, Layout.controlHeightTouch)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Space.s3)),
          shape: const WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(buttonText),
          foregroundColor: WidgetStatePropertyAll(c.accent),
          overlayColor: overlay(c.accent),
          side: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.focused) ? focusRing : null),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(buttonShape),
          foregroundColor: WidgetStatePropertyAll(c.textMuted),
          overlayColor: overlay(c.textPrimary),
          iconSize: const WidgetStatePropertyAll(18),
          side: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.focused) ? focusRing : null),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(type.small.copyWith(fontWeight: FontWeight.w500)),
          side: WidgetStatePropertyAll(BorderSide(color: c.borderStrong)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.surfaceMuted : c.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.textPrimary : c.textMuted,
          ),
          overlayColor: overlay(c.textPrimary),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceMuted,
        side: BorderSide(color: c.border),
        shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        labelStyle: type.caption.copyWith(color: c.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: Space.s1),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.textPrimary, borderRadius: Radii.smAll),
        textStyle: type.caption.copyWith(color: c.surface),
        padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s1),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: type.body.copyWith(color: c.surface),
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        width: 400,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.xlAll,
          side: BorderSide(color: c.border),
        ),
        titleTextStyle: type.h2,
        contentTextStyle: type.body.copyWith(color: c.textMuted),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        elevation: 6,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: BorderSide(color: c.border),
        ),
        textStyle: type.body,
        menuPadding: const EdgeInsets.symmetric(vertical: Space.s1),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: Radii.mdAll,
              side: BorderSide(color: c.border),
            ),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accentSubtle,
        selectedIconTheme: IconThemeData(color: c.accent, size: 20),
        unselectedIconTheme: IconThemeData(color: c.textMuted, size: 20),
        indicatorShape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accentSubtle,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => type.caption.copyWith(color: s.contains(WidgetState.selected) ? c.textPrimary : c.textMuted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.accent : c.textMuted, size: 20),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.surfaceMuted),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.borderStrong),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.2),
      ),
    );
  }
}
