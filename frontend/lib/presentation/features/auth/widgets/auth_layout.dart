import 'package:flutter/material.dart';

import '../../../components/brand.dart';
import '../../../layout/breakpoints.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';

/// Split auth layout: brand panel left (≥1024), form right. Below that, the
/// form alone with the logo on top.
class AuthLayout extends StatelessWidget {
  final String tabTitle;
  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;

  const AuthLayout({
    super.key,
    required this.tabTitle,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final t = context.text;

    final formColumn = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
                const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
                const SizedBox(height: Space.s10),
              ],
              Semantics(header: true, child: Text(title, style: t.h1)),
              const SizedBox(height: Space.s2),
              Text(subtitle, style: t.body.copyWith(color: context.colors.textMuted)),
              const SizedBox(height: Space.s8),
              form,
              const SizedBox(height: Space.s6),
              footer,
            ],
          ),
        ),
      ),
    );

    return Title(
      title: '$tabTitle · Shortly',
      color: context.colors.accent,
      child: Scaffold(
        body: isDesktop
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 6, child: formColumn),
                ],
              )
            : SafeArea(child: formColumn),
      ),
    );
  }
}

/// Marketing panel. Uses the light palette's deep indigo in both themes so
/// the brand reads the same in light and dark mode.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _ink = AppColors.light;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final deep = Color.lerp(_ink.accent, const Color(0xFF000000), 0.45)!;
    final onBrand = _ink.onAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_ink.accent, deep]),
      ),
      padding: const EdgeInsets.all(Space.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: onBrand, borderRadius: BorderRadius.circular(7)),
                child: Icon(Icons.link_rounded, size: 18, color: _ink.accent),
              ),
              const SizedBox(width: Space.s2),
              Text('Shortly', style: t.h2.copyWith(color: onBrand)),
            ],
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Short links.\nClear insights.', style: t.display.copyWith(color: onBrand, fontSize: 40)),
                const SizedBox(height: Space.s4),
                Text(
                  'Turn long URLs into memorable links, pick your own alias, and see who clicks.',
                  style: t.body.copyWith(color: onBrand.withValues(alpha: 0.8), fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: Space.s8),
                for (final (icon, text) in const [
                  (Icons.bolt_rounded, 'Shorten any URL in one click'),
                  (Icons.edit_rounded, 'Custom aliases with live availability'),
                  (Icons.bar_chart_rounded, 'Click counts, devices and browsers'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s3),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: onBrand.withValues(alpha: 0.12), borderRadius: Radii.mdAll),
                          child: Icon(icon, size: 16, color: onBrand),
                        ),
                        const SizedBox(width: Space.s3),
                        Text(text, style: t.body.copyWith(color: onBrand.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                const SizedBox(height: Space.s8),
                const _MockLinkCard(),
              ],
            ),
          ),
          const Spacer(),
          Text('© Shortly', style: t.caption.copyWith(color: onBrand.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// Decorative product preview: a link row with a click count.
class _MockLinkCard extends StatelessWidget {
  const _MockLinkCard();

  static const _ink = AppColors.light;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(Space.s4),
        decoration: BoxDecoration(
          color: _ink.surface,
          borderRadius: Radii.lgAll,
          boxShadow: Elevation.popover(Brightness.dark),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _ink.surfaceMuted, borderRadius: Radii.mdAll),
              child: Text('G', style: t.h3.copyWith(color: _ink.textMuted)),
            ),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('localhost:5000/launch', style: t.mono.copyWith(color: _ink.textPrimary)),
                  Text('github.com/acme/product/releases/v2', style: t.small.copyWith(color: _ink.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 2),
              decoration: BoxDecoration(color: _ink.accentSubtle, borderRadius: Radii.smAll),
              child: Text('1,284 clicks', style: t.caption.copyWith(color: _ink.accent)),
            ),
          ],
        ),
      ),
    );
  }
}
