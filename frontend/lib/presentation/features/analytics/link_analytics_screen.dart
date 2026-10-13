import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../repositories/url_repository.dart';
import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/bar_list.dart';
import '../../components/brand.dart';
import '../../components/coming_soon_card.dart';
import '../../components/copy_button.dart';
import '../../components/empty_state.dart';
import '../../components/qr_dialog.dart';
import '../../components/skeleton.dart';
import '../../components/stat_tile.dart';
import '../../components/status_badge.dart';
import '../../layout/page_scaffold.dart';
import '../../layout/responsive_grid.dart';
import '../../theme/app_tokens.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/formatters.dart';
import '../../utils/link_launcher.dart';
import 'cubit/link_analytics_cubit.dart';
import 'widgets/visits_table.dart';

class LinkAnalyticsScreen extends StatelessWidget {
  final String linkId;

  const LinkAnalyticsScreen({super.key, required this.linkId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Keyed by id so navigating between links recreates the cubit.
      key: ValueKey(linkId),
      create: (_) => LinkAnalyticsCubit(sl<UrlRepository>(), linkId)..load(),
      child: const _LinkAnalyticsView(),
    );
  }
}

class _LinkAnalyticsView extends StatelessWidget {
  const _LinkAnalyticsView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LinkAnalyticsCubit>().state;
    final t = context.text;
    final c = context.colors;

    final breadcrumb = Padding(
      padding: const EdgeInsets.only(bottom: Space.s2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => context.go('/links'),
            borderRadius: Radii.smAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('Links', style: t.small.copyWith(color: c.textMuted)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s1),
            child: Icon(Icons.chevron_right_rounded, size: 14, color: c.textMuted),
          ),
          Text(
            state is LinkAnalyticsLoaded ? state.link.shortCode : '…',
            style: t.small.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );

    return switch (state) {
      LinkAnalyticsLoading() => PageScaffold(
        title: 'Link analytics',
        leading: breadcrumb,
        child: const _DetailSkeleton(),
      ),
      LinkAnalyticsError(:final message) => PageScaffold(
        title: 'Link analytics',
        leading: breadcrumb,
        child: EmptyState(
          icon: Icons.link_off_rounded,
          isError: true,
          title: "Couldn't load this link",
          message: message,
          action: Wrap(
            spacing: Space.s2,
            children: [
              AppButton.secondary(label: 'Back to links', onPressed: () => context.go('/links')),
              AppButton(label: 'Try again', onPressed: () => context.read<LinkAnalyticsCubit>().load()),
            ],
          ),
        ),
      ),
      LinkAnalyticsLoaded() => _Loaded(state: state, breadcrumb: breadcrumb),
    };
  }
}

class _Loaded extends StatelessWidget {
  final LinkAnalyticsLoaded state;
  final Widget breadcrumb;

  const _Loaded({required this.state, required this.breadcrumb});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final link = state.link;
    final a = state.analytics;
    const sampleNote = 'Based on last 10 visits';

    Widget breakdown(String title, Map<String, int> data) => AppCard(
      title: title,
      subtitle: sampleNote,
      child: data.isEmpty
          ? Text('No visits yet', style: t.small)
          : BarList(items: [for (final e in data.entries) BarItem(e.key, e.value)], valueLabel: 'visits'),
    );

    return PageScaffold(
      title: Fmt.stripScheme(link.shortUrl),
      tabTitle: '/${link.shortCode} analytics',
      leading: breadcrumb,
      actions: [
        CopyButton(value: link.shortUrl),
        AppButton.secondary(
          label: 'QR code',
          icon: Icons.qr_code_2_rounded,
          onPressed: () => showQrDialog(context, url: link.shortUrl, code: link.shortCode),
        ),
        AppButton.secondary(
          label: 'Open',
          icon: Icons.open_in_new_rounded,
          onPressed: () => openExternal(link.shortUrl),
        ),
        AppButton.secondary(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => context.read<LinkAnalyticsCubit>().load(),
        ),
      ],
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Destination + status strip.
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: Space.s5, vertical: Space.s4),
              child: Wrap(
                spacing: Space.s4,
                runSpacing: Space.s3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HostAvatar(url: link.originalUrl, size: 28),
                      const SizedBox(width: Space.s3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DESTINATION', style: t.overline),
                            Text(link.originalUrl, style: t.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const StatusBadge('Active', tone: BadgeTone.success, icon: Icons.circle),
                  if ((link.customAlias ?? '').isNotEmpty) const StatusBadge('Custom alias', tone: BadgeTone.accent),
                  Text('Created ${Fmt.date(link.createdAt)}', style: t.small),
                ],
              ),
            ),
            const SizedBox(height: Space.s4),
            ResponsiveRow(
              gap: Space.s4,
              children: [
                ResponsiveCol(
                  medium: 4,
                  child: StatTile(
                    label: 'Total clicks',
                    icon: Icons.ads_click_rounded,
                    value: Fmt.count(a.totalClicks),
                  ),
                ),
                ResponsiveCol(
                  medium: 4,
                  child: StatTile(
                    label: 'Last visited',
                    icon: Icons.schedule_rounded,
                    value: a.lastVisitedAt == null ? 'Never' : Fmt.relative(a.lastVisitedAt!),
                    caption: a.lastVisitedAt == null ? 'No visits yet' : Fmt.dateTime(a.lastVisitedAt!),
                  ),
                ),
                ResponsiveCol(
                  medium: 4,
                  child: StatTile(
                    label: 'Link age',
                    icon: Icons.cake_outlined,
                    value: Fmt.age(a.createdAt),
                    caption: 'Since ${Fmt.date(a.createdAt)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s6),
            ResponsiveRow(
              children: [
                ResponsiveCol(
                  medium: 8,
                  child: AppCard(
                    title: 'Recent visits',
                    subtitle: 'The ${a.recentVisits.length} most recent of ${Fmt.count(a.totalClicks)} total',
                    child: VisitsTable(visits: a.recentVisits, agents: state.agents),
                  ),
                ),
                ResponsiveCol(
                  medium: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      breakdown('Browsers', state.breakdown((u) => u.browser)),
                      const SizedBox(height: Space.s4),
                      breakdown('Operating systems', state.breakdown((u) => u.os)),
                      const SizedBox(height: Space.s4),
                      breakdown('Devices', state.breakdown((u) => u.device)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s6),
            const ComingSoonCard(
              title: 'Clicks over time',
              message: 'Daily click history needs server-side aggregation — coming soon.',
            ),
            const SizedBox(height: Space.s6),
            const ResponsiveRow(
              children: [
                ResponsiveCol(
                  medium: 6,
                  child: ComingSoonCard(
                    title: 'Top referrers',
                    message: 'Referrers are not recorded yet.',
                    icon: Icons.travel_explore_rounded,
                    asBars: true,
                  ),
                ),
                ResponsiveCol(
                  medium: 6,
                  child: ComingSoonCard(
                    title: 'Countries',
                    message: 'Visitor location is not recorded yet.',
                    icon: Icons.public_rounded,
                    asBars: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(Space.s5),
      alignment: Alignment.topLeft,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120),
          SizedBox(height: Space.s3),
          SkeletonBox(width: 200, height: 20),
        ],
      ),
    );
    return SkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(72),
          const SizedBox(height: Space.s4),
          ResponsiveRow(
            gap: Space.s4,
            children: [for (var i = 0; i < 3; i++) ResponsiveCol(medium: 4, child: block(104))],
          ),
          const SizedBox(height: Space.s6),
          block(320),
        ],
      ),
    );
  }
}
