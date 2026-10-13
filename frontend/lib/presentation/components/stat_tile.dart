import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// KPI tile: overline label, large tabular metric, optional caption.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData? icon;

  /// Renders [value] in the mono face (e.g. a short link as the "top link").
  final bool monoValue;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.monoValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      container: true,
      label: '$label: $value${caption != null ? ', $caption' : ''}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Space.s5),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: Radii.lgAll,
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[Icon(icon, size: 14, color: c.textMuted), const SizedBox(width: Space.s2)],
                  Expanded(
                    child: Text(label.toUpperCase(), style: t.overline, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: Space.s2),
              Text(
                value,
                style: monoValue ? t.mono.copyWith(fontSize: 20, height: 1.4) : t.metric,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (caption != null) ...[
                const SizedBox(height: Space.s1),
                Text(caption!, style: t.small, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
