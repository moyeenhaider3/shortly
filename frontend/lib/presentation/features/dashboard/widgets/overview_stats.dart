import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/url/url_bloc.dart';
import '../../../../bloc/url/url_state.dart';
import '../../../components/stat_tile.dart';
import '../../../theme/app_tokens.dart';
import '../../../utils/formatters.dart';
import '../../analytics/link_stats.dart';

/// KPI tiles derived from the loaded links. Stacks in a narrow side column,
/// becomes a 2-up grid when given more room.
class OverviewStats extends StatelessWidget {
  const OverviewStats({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UrlBloc, UrlState, LinkStats>(
      selector: (state) => LinkStats.from(state.urls),
      builder: (context, stats) {
        final loading = context.select<UrlBloc, bool>((b) => b.state is UrlLoading || b.state is UrlInitial);
        String v(String value) => loading && stats.totalLinks == 0 ? '—' : value;
        final top = stats.topLink;
        final tiles = [
          StatTile(label: 'Total links', icon: Icons.link_rounded, value: v(Fmt.count(stats.totalLinks))),
          StatTile(label: 'Total clicks', icon: Icons.ads_click_rounded, value: v(Fmt.count(stats.totalClicks))),
          StatTile(
            label: 'Avg. clicks / link',
            icon: Icons.functions_rounded,
            value: v(stats.avgClicks.toStringAsFixed(stats.avgClicks < 10 ? 1 : 0)),
          ),
          StatTile(
            label: 'Top link',
            icon: Icons.emoji_events_outlined,
            value: top == null ? '—' : '/${top.shortCode}',
            caption: top == null ? 'No clicks yet' : '${Fmt.count(top.clickCount)} clicks',
            monoValue: top != null,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 440 ? 2 : 1;
            final w = (constraints.maxWidth - Space.s4 * (cols - 1)) / cols;
            return Wrap(
              spacing: Space.s4,
              runSpacing: Space.s4,
              children: [for (final tile in tiles) SizedBox(width: w, child: tile)],
            );
          },
        );
      },
    );
  }
}
