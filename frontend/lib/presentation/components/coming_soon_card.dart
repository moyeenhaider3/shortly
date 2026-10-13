import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import 'app_card.dart';
import 'status_badge.dart';

/// Reserved slot for a chart the backend can't feed yet. Shows a faint
/// static silhouette so the page layout is final today.
class ComingSoonCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool asBars;

  const ComingSoonCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.show_chart_rounded,
    this.asBars = false,
  });

  static const _heights = [0.35, 0.55, 0.45, 0.7, 0.5, 0.8, 0.6, 0.9, 0.65, 0.75, 0.5, 0.85];
  static const _widths = [0.9, 0.7, 0.5, 0.35, 0.2];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      title: title,
      trailing: const StatusBadge('Coming soon'),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: asBars
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final w in _widths) ...[
                            FractionallySizedBox(
                              widthFactor: w,
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: Radii.smAll),
                              ),
                            ),
                            const SizedBox(height: Space.s2),
                          ],
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final h in _heights)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: FractionallySizedBox(
                                  heightFactor: h,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: c.surfaceMuted,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: Radii.mdAll,
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: c.textMuted),
                    const SizedBox(width: Space.s2),
                    Flexible(child: Text(message, style: context.text.small)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
