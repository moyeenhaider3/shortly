import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/url_model.dart';
import '../../../components/brand.dart';
import '../../../components/copy_button.dart';
import '../../../components/skeleton.dart';
import '../../../components/status_badge.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/formatters.dart';
import 'link_actions.dart';

/// Below this *container* width the table turns into a list of cards.
const double _tableMinWidth = 720;

// Column flex shared by header and rows so they always line up.
const _flexLink = 5, _flexDestination = 5, _flexClicks = 2, _flexCreated = 2;
const double _actionsWidth = 148;

bool get _hoverCapable =>
    !(defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

/// Responsive links view: a dense table on wide containers, cards on narrow.
class LinksTable extends StatelessWidget {
  final List<UrlModel> items;
  final int maxClicks;

  const LinksTable({super.key, required this.items, required this.maxClicks});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _tableMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final u in items) ...[LinkCard(url: u), const SizedBox(height: Space.s2)],
            ],
          );
        }
        return _TableFrame(
          rows: [for (final u in items) LinkRow(key: ValueKey(u.id), url: u, maxClicks: maxClicks)],
        );
      },
    );
  }
}

class _TableFrame extends StatelessWidget {
  final List<Widget> rows;
  const _TableFrame({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget head(String label, int flex, {TextAlign align = TextAlign.left}) => Expanded(
      flex: flex,
      child: Text(label.toUpperCase(), style: t.overline, textAlign: align),
    );

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: c.surfaceMuted,
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
            child: Row(
              children: [
                head('Link', _flexLink),
                head('Destination', _flexDestination),
                head('Clicks', _flexClicks, align: TextAlign.right),
                const SizedBox(width: Space.s6),
                head('Created', _flexCreated),
                const SizedBox(width: _actionsWidth),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) Divider(height: 1, color: c.border), rows[i]],
        ],
      ),
    );
  }
}

class LinkRow extends StatefulWidget {
  final UrlModel url;
  final int maxClicks;

  const LinkRow({super.key, required this.url, required this.maxClicks});

  @override
  State<LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<LinkRow> {
  bool _hover = false;
  bool _focusWithin = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final u = widget.url;
    final showActions = !_hoverCapable || _hover || _focusWithin;
    final fraction = widget.maxClicks == 0 ? 0.0 : u.clickCount / widget.maxClicks;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onFocusChange: (has) => setState(() => _focusWithin = has),
        child: Material(
          color: _hover ? c.surfaceMuted.withValues(alpha: 0.6) : c.surface,
          child: InkWell(
            onTap: () => context.go('/links/${u.id}'),
            hoverColor: const Color(0x00000000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
              child: Row(
                children: [
                  Expanded(
                    flex: _flexLink,
                    child: Row(
                      children: [
                        HostAvatar(url: u.originalUrl),
                        const SizedBox(width: Space.s3),
                        Flexible(
                          child: Tooltip(
                            message: u.shortUrl,
                            child: Text(Fmt.stripScheme(u.shortUrl), style: t.mono, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        if ((u.customAlias ?? '').isNotEmpty) ...[
                          const SizedBox(width: Space.s2),
                          const StatusBadge('Custom', tone: BadgeTone.accent),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.s4),
                  Expanded(
                    flex: _flexDestination,
                    child: Tooltip(
                      message: u.originalUrl,
                      waitDuration: const Duration(milliseconds: 600),
                      child: Text(u.originalUrl, style: t.small, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  Expanded(
                    flex: _flexClicks,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Fmt.count(u.clickCount),
                          style: t.body.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                        const SizedBox(height: 4),
                        // Inline bar on a shared scale: the busiest link fills it.
                        ExcludeSemantics(
                          child: Container(
                            width: 48,
                            height: 3,
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(2)),
                            child: FractionallySizedBox(
                              widthFactor: fraction,
                              child: Container(
                                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.s6),
                  Expanded(
                    flex: _flexCreated,
                    child: Tooltip(
                      message: Fmt.dateTime(u.createdAt),
                      child: Text(Fmt.relative(u.createdAt), style: t.small),
                    ),
                  ),
                  SizedBox(
                    width: _actionsWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: showActions ? 1 : 0,
                        duration: Motion.fast,
                        child: LinkActionButtons(url: u),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact (phone / narrow container) representation of a link.
class LinkCard extends StatelessWidget {
  final UrlModel url;

  const LinkCard({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final u = url;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgAll,
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/links/${u.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s1, Space.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HostAvatar(url: u.originalUrl, size: 28),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Text(Fmt.stripScheme(u.shortUrl), style: t.mono, overflow: TextOverflow.ellipsis),
                  ),
                  CopyButton(value: u.shortUrl),
                  LinkActionButtons(url: u, menuOnly: true),
                ],
              ),
              const SizedBox(height: Space.s1),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: Space.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.originalUrl, style: t.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Space.s2),
                    Wrap(
                      spacing: Space.s3,
                      runSpacing: Space.s1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Meta(icon: Icons.ads_click_rounded, text: '${Fmt.count(u.clickCount)} clicks'),
                        _Meta(icon: Icons.schedule_rounded, text: Fmt.relative(u.createdAt)),
                        if ((u.customAlias ?? '').isNotEmpty) const StatusBadge('Custom', tone: BadgeTone.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.colors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: context.text.caption),
      ],
    );
  }
}

/// Placeholder rows matching the table/card layout while links load.
class LinksTableSkeleton extends StatelessWidget {
  final int rows;
  const LinksTableSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SkeletonScope(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: Radii.lgAll,
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows; i++) ...[
              if (i > 0) Divider(height: 1, color: c.border),
              Padding(
                padding: const EdgeInsets.all(Space.s4),
                child: Row(
                  children: [
                    const SkeletonBox(width: 32, height: 32, radius: Radii.mdAll),
                    const SizedBox(width: Space.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(widthFactor: 0.35 + (i % 3) * 0.1, child: const SkeletonBox(height: 12)),
                          const SizedBox(height: Space.s2),
                          FractionallySizedBox(widthFactor: 0.6 - (i % 2) * 0.15, child: const SkeletonBox(height: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
