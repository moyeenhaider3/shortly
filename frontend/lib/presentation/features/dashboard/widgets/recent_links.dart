import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../bloc/url/url_bloc.dart';
import '../../../../bloc/url/url_event.dart';
import '../../../../bloc/url/url_state.dart';
import '../../../../models/url_model.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/brand.dart';
import '../../../components/copy_button.dart';
import '../../../components/empty_state.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/formatters.dart';
import '../../links/widgets/links_table.dart';

class RecentLinks extends StatelessWidget {
  const RecentLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UrlBloc>().state;
    final recent = state.urls.take(5).toList();

    final Widget body;
    if (recent.isEmpty && (state is UrlLoading || state is UrlInitial)) {
      body = const LinksTableSkeleton(rows: 3);
    } else if (recent.isEmpty && state is UrlError && state.action == UrlAction.fetch) {
      body = EmptyState(
        icon: Icons.cloud_off_rounded,
        isError: true,
        title: "Couldn't load your links",
        message: state.message,
        action: AppButton.secondary(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onPressed: () => context.read<UrlBloc>().add(FetchUrls()),
        ),
      );
    } else if (recent.isEmpty) {
      body = const EmptyState(
        icon: Icons.link_rounded,
        title: 'No links yet',
        message: 'Links you create appear here.',
      );
    } else {
      body = Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.colors.border),
            _RecentRow(url: recent[i]),
          ],
        ],
      );
    }

    return AppCard(
      title: 'Recent links',
      padding: const EdgeInsets.fromLTRB(Space.s5, Space.s4, Space.s5, Space.s2),
      trailing: TextButton(onPressed: () => context.go('/links'), child: const Text('View all →')),
      child: body,
    );
  }
}

class _RecentRow extends StatelessWidget {
  final UrlModel url;
  const _RecentRow({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return InkWell(
      onTap: () => context.go('/links/${url.id}'),
      borderRadius: Radii.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s3),
        child: Row(
          children: [
            HostAvatar(url: url.originalUrl),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.stripScheme(url.shortUrl), style: t.mono, overflow: TextOverflow.ellipsis),
                  Text(url.originalUrl, style: t.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: Space.s3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.count(url.clickCount),
                  style: t.h3.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                Text('clicks', style: t.caption.copyWith(color: c.textMuted)),
              ],
            ),
            const SizedBox(width: Space.s2),
            CopyButton(value: url.shortUrl),
          ],
        ),
      ),
    );
  }
}
