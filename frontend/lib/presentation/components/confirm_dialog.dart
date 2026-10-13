import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import 'app_button.dart';

/// Returns true when the user confirms. Esc / barrier tap cancels.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Space.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: context.text.h2),
              const SizedBox(height: Space.s2),
              Text(message, style: context.text.body.copyWith(color: context.colors.textMuted)),
              const SizedBox(height: Space.s6),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: Space.s2,
                runSpacing: Space.s2,
                children: [
                  AppButton.secondary(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
                  AppButton(
                    label: confirmLabel,
                    variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
