import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

enum ToastTone { success, error, info }

/// Themed floating snackbar with a leading status icon.
abstract final class AppToast {
  static void show(BuildContext context, String message, {ToastTone tone = ToastTone.info}) {
    final c = context.colors;
    final (icon, color) = switch (tone) {
      // Inverse surface: use the opposite theme's status colours for contrast.
      ToastTone.success => (Icons.check_circle_rounded, (context.isDark ? AppColors.light : AppColors.dark).success),
      ToastTone.error => (Icons.error_rounded, (context.isDark ? AppColors.light : AppColors.dark).danger),
      ToastTone.info => (Icons.info_rounded, c.surface),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: Space.s3),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) => show(context, message, tone: ToastTone.success);
  static void error(BuildContext context, String message) => show(context, message, tone: ToastTone.error);
}
