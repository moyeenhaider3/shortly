import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// Inline error banner shown inside forms (instead of a transient snackbar).
class InlineAlert extends StatelessWidget {
  final String message;

  const InlineAlert(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s3),
        decoration: BoxDecoration(
          color: c.dangerSubtle,
          borderRadius: Radii.mdAll,
          border: Border.all(color: c.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: c.danger),
            const SizedBox(width: Space.s2),
            Expanded(
              child: Text(message, style: context.text.small.copyWith(color: c.danger)),
            ),
          ],
        ),
      ),
    );
  }
}
