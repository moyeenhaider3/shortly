import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import '../utils/formatters.dart';

/// Logo mark + optional wordmark.
class BrandLogo extends StatelessWidget {
  final bool showWordmark;
  final double size;

  const BrandLogo({super.key, this.showWordmark = true, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Shortly',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(size * 0.25)),
            child: Icon(Icons.link_rounded, size: size * 0.62, color: c.onAccent),
          ),
          if (showWordmark) ...[
            const SizedBox(width: Space.s2),
            Text('Shortly', style: context.text.h2.copyWith(fontSize: size * 0.6, letterSpacing: -0.3)),
          ],
        ],
      ),
    );
  }
}

/// Square letter avatar for a destination host, e.g. "G" for github.com.
class HostAvatar extends StatelessWidget {
  final String url;
  final double size;

  const HostAvatar({super.key, required this.url, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final host = Fmt.host(url);
    final letter = host.isEmpty ? '?' : host[0].toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: Radii.mdAll,
          border: Border.all(color: c.border),
        ),
        child: Text(letter, style: context.text.h3.copyWith(color: c.textMuted)),
      ),
    );
  }
}

/// Initials avatar for the signed-in user.
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;

  const UserAvatar({super.key, required this.name, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty ? '?' : (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.accentSubtle, shape: BoxShape.circle),
        child: Text(
          initials,
          style: context.text.caption.copyWith(color: c.accent, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
