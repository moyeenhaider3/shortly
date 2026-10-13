import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// Centered icon + message + optional action, for empty lists, no results
/// and error states.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool isError;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s12, horizontal: Space.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isError ? c.dangerSubtle : c.surfaceMuted,
              borderRadius: Radii.lgAll,
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, size: 22, color: isError ? c.danger : c.textMuted),
          ),
          const SizedBox(height: Space.s4),
          Text(title, style: context.text.h3, textAlign: TextAlign.center),
          const SizedBox(height: Space.s1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(message, style: context.text.small, textAlign: TextAlign.center),
          ),
          if (action != null) ...[const SizedBox(height: Space.s5), action!],
        ],
      ),
    );
  }
}
