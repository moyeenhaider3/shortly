import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// Flat surface with a 1px border, the base container of the design system.
class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  /// Optional accent-tinted border, e.g. to highlight a freshly created link.
  final bool highlighted;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(Space.s5),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.curve,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: highlighted ? c.accent.withValues(alpha: 0.5) : c.border),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!, style: context.text.h3),
                      if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: context.text.small)],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: Space.s4),
          ],
          child,
        ],
      ),
    );
  }
}
