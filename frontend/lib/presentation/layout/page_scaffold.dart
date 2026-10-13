import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import 'breakpoints.dart';

/// Standard page frame inside the app shell: browser-tab title, header row,
/// scrollable body capped at a readable max width with responsive gutters.
class PageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget child;

  /// Browser tab title; defaults to [title].
  final String? tabTitle;

  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.tabTitle,
  });

  @override
  Widget build(BuildContext context) {
    final bp = context.breakpoint;
    final gutter = responsiveValue(bp, compact: Space.s4, medium: Space.s6, expanded: Space.s8);
    final maxWidth = bp == Breakpoint.large ? Layout.contentMaxWidthLarge : Layout.contentMaxWidth;

    final header = Wrap(
      spacing: Space.s4,
      runSpacing: Space.s3,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?leading,
            Semantics(header: true, child: Text(title, style: context.text.h1)),
            if (subtitle != null) ...[const SizedBox(height: Space.s1), Text(subtitle!, style: context.text.small)],
          ],
        ),
        if (actions.isNotEmpty) Wrap(spacing: Space.s2, runSpacing: Space.s2, children: actions),
      ],
    );

    return Title(
      title: '${tabTitle ?? title} · Shortly',
      color: context.colors.accent,
      child: SingleChildScrollView(
        primary: true,
        padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, Space.s12),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                SizedBox(height: bp == Breakpoint.compact ? Space.s5 : Space.s8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
