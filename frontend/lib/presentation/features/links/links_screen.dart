import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/url/url_bloc.dart';
import '../../../bloc/url/url_event.dart';
import '../../../bloc/url/url_state.dart';
import '../../components/app_button.dart';
import '../../components/empty_state.dart';
import '../../layout/page_scaffold.dart';
import '../../theme/app_tokens.dart';
import 'cubit/links_view_cubit.dart';
import 'widgets/links_table.dart';
import 'widgets/links_toolbar.dart';
import 'widgets/pagination_bar.dart';

class LinksScreen extends StatelessWidget {
  const LinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LinksViewCubit(context.read<UrlBloc>().state.urls),
      child: BlocListener<UrlBloc, UrlState>(
        listenWhen: (prev, curr) => !identical(prev.urls, curr.urls),
        listener: (context, state) => context.read<LinksViewCubit>().updateSource(state.urls),
        child: PageScaffold(
          title: 'Links',
          subtitle: 'Every active short link you own.',
          actions: [
            AppButton.secondary(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              onPressed: () => context.read<UrlBloc>().add(FetchUrls()),
            ),
            AppButton(label: 'Create link', icon: Icons.add_rounded, onPressed: () => context.go('/')),
          ],
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinksToolbar(),
              SizedBox(height: Space.s4),
              _LinksBody(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinksBody extends StatelessWidget {
  const _LinksBody();

  @override
  Widget build(BuildContext context) {
    final urlState = context.watch<UrlBloc>().state;
    final view = context.watch<LinksViewCubit>().state;
    final page = view.page;
    final hasData = urlState.urls.isNotEmpty;

    if (!hasData && (urlState is UrlLoading || urlState is UrlInitial)) {
      return const LinksTableSkeleton(rows: 6);
    }
    if (!hasData && urlState is UrlError && urlState.action == UrlAction.fetch) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        isError: true,
        title: "Couldn't load your links",
        message: urlState.message,
        action: AppButton.secondary(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onPressed: () => context.read<UrlBloc>().add(FetchUrls()),
        ),
      );
    }
    if (page.total == 0) {
      return EmptyState(
        icon: Icons.link_rounded,
        title: 'No links yet',
        message: 'Shorten your first URL and it will show up here with its click count.',
        action: AppButton(label: 'Create your first link', icon: Icons.add_rounded, onPressed: () => context.go('/')),
      );
    }
    if (page.matched == 0) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No links match',
        message: 'Try a different search term or filter.',
        action: AppButton.secondary(
          label: 'Clear filters',
          onPressed: () => context.read<LinksViewCubit>().clearFilters(),
        ),
      );
    }

    final cubit = context.read<LinksViewCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinksTable(items: page.items, maxClicks: page.maxClicks),
        PaginationBar(page: page, onPrevious: cubit.previousPage, onNext: cubit.nextPage),
      ],
    );
  }
}
