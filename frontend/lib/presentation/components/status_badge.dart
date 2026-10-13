import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

enum BadgeTone { neutral, accent, success, danger }

/// Small pill used for status and metadata. Always carries text so meaning
/// never depends on colour alone.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      BadgeTone.neutral => (c.surfaceMuted, c.textMuted),
      BadgeTone.accent => (c.accentSubtle, c.accent),
      BadgeTone.success => (c.successSubtle, c.success),
      BadgeTone.danger => (c.dangerSubtle, c.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.smAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: Space.s1)],
          Text(label, style: context.text.caption.copyWith(color: fg)),
        ],
      ),
    );
  }
}
