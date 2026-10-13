import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../bloc/url/url_bloc.dart';
import '../../../bloc/url/url_event.dart';
import '../../../bloc/url/url_state.dart';
import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../components/bar_list.dart';
import '../../components/column_chart.dart';
import '../../components/coming_soon_card.dart';
import '../../components/empty_state.dart';
import '../../components/stat_tile.dart';
import '../../layout/page_scaffold.dart';
import '../../layout/responsive_grid.dart';
import '../../utils/formatters.dart';
import 'link_stats.dart';

/// Account-level analytics. Everything here is derived from `GET /urls`;
/// time-series clicks need server aggregation and are reserved as a slot.
class AnalyticsOverviewScreen extends StatelessWidget {
  const AnalyticsOverviewScreen({super.key});

  static final _weekLabel = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Analytics',
      subtitle: 'How your links are performing across your account.',
      actions: [
        AppButton.secondary(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => context.read<UrlBloc>().add(FetchUrls()),
        ),
      ],
      child: BlocSelector<UrlBloc, UrlState, LinkStats>(
        selector: (state) => LinkStats.from(state.urls),
        builder: (context, stats) {
          final urlState = context.read<UrlBloc>().state;
          if (stats.totalLinks == 0 && urlState is UrlError && urlState.action == UrlAction.fetch) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              isError: true,
              title: "Couldn't load analytics",
              message: urlState.message,
              action: AppButton.secondary(
                label: 'Try again',
                onPressed: () => context.read<UrlBloc>().add(FetchUrls()),
              ),
            );
          }

          final kpis = [
            StatTile(label: 'Total links', icon: Icons.link_rounded, value: Fmt.count(stats.totalLinks)),
            StatTile(label: 'Total clicks', icon: Icons.ads_click_rounded, value: Fmt.count(stats.totalClicks)),
            StatTile(
              label: 'Avg. clicks / link',
              icon: Icons.functions_rounded,
              value: stats.avgClicks.toStringAsFixed(stats.avgClicks < 10 ? 1 : 0),
            ),
            StatTile(
              label: 'New this week',
              icon: Icons.add_link_rounded,
              value: Fmt.count(stats.createdLast7Days),
              caption: 'Links created in the last 7 days',
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResponsiveRow(gap: 16, children: [for (final k in kpis) ResponsiveCol(child: k, compact: 6, medium: 3)]),
              const SizedBox(height: 24),
              ResponsiveRow(
                children: [
                  ResponsiveCol(
                    medium: 7,
                    child: AppCard(
                      title: 'Top links',
                      subtitle: 'Ranked by total clicks',
                      child: stats.topLinks.isEmpty
                          ? const EmptyState(
                              icon: Icons.ads_click_rounded,
                              title: 'No clicks yet',
                              message: 'Share a short link — clicks will rank here.',
                            )
                          : BarList(
                              items: [
                                for (final u in stats.topLinks)
                                  BarItem(
                                    '/${u.shortCode}',
                                    u.clickCount,
                                    mono: true,
                                    onTap: () => context.go('/links/${u.id}'),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  ResponsiveCol(
                    medium: 5,
                    child: AppCard(
                      title: 'Links created',
                      subtitle: 'Per week, last 12 weeks',
                      child: ColumnChart(
                        labelEvery: 3,
                        data: [
                          for (final w in stats.createdPerWeek)
                            ColumnDatum(
                              label: _weekLabel.format(w.start),
                              tooltip: 'Week of ${_weekLabel.format(w.start)}',
                              value: w.count,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const ComingSoonCard(
                title: 'Clicks over time',
                message: 'Time-series analytics need server-side aggregation — coming soon.',
              ),
            ],
          );
        },
      ),
    );
  }
}
