import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Filled/outlined button with a built-in loading state that keeps its width,
/// so the layout doesn't jump while a request is in flight.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.expand = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = variant == AppButtonVariant.secondary ? c.textPrimary : c.onAccent;

    final content = Stack(
      alignment: Alignment.center,
      children: [
        // Keep the label in the tree (invisible) so the width stays stable.
        Visibility(
          visible: !loading,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: variant == AppButtonVariant.secondary ? c.textMuted : fg),
                const SizedBox(width: Space.s2),
              ],
              Text(label),
            ],
          ),
        ),
        if (loading) SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg)),
      ],
    );

    final onTap = loading ? () {} : onPressed;
    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: onTap, child: content),
      AppButtonVariant.danger => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: c.onAccent),
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(onPressed: onTap, child: content),
    };

    return Semantics(
      button: true,
      label: loading ? '$label, loading' : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
