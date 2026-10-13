import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/url/url_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../models/url_model.dart';
import '../../../repositories/url_repository.dart';
import '../../../core/di/injection_container.dart';
import '../../components/app_toast.dart';
import '../../layout/page_scaffold.dart';
import '../../layout/responsive_grid.dart';
import '../../theme/app_tokens.dart';
import 'cubit/alias_check_cubit.dart';
import 'widgets/create_link_panel.dart';
import 'widgets/created_link_result.dart';
import 'widgets/overview_stats.dart';
import 'widgets/recent_links.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UrlModel? _created;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// "localhost:5000/" — taken from an existing short link when available,
  /// so it matches exactly what the backend generates.
  String _domainPrefix(List<UrlModel> urls) {
    final source = urls.isNotEmpty ? Uri.tryParse(urls.first.shortUrl) : null;
    final uri = (source != null && source.host.isNotEmpty) ? source : Uri.parse(ApiClient.baseUrl);
    return '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/';
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthBloc, String>((b) => b.state.user?.name ?? '');
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final prefix = context.select<UrlBloc, String>((b) => _domainPrefix(b.state.urls));

    return BlocProvider(
      create: (_) => AliasCheckCubit(sl<UrlRepository>()),
      child: PageScaffold(
        title: firstName.isEmpty ? 'Dashboard' : '${_greeting()}, $firstName',
        tabTitle: 'Dashboard',
        subtitle: 'Create short links and keep an eye on how they perform.',
        child: ResponsiveRow(
          children: [
            ResponsiveCol(
              medium: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CreateLinkPanel(
                    domainPrefix: prefix,
                    onCreated: (url) {
                      setState(() => _created = url);
                      AppToast.success(context, 'Short link created');
                    },
                  ),
                  if (_created != null) ...[
                    const SizedBox(height: Space.s4),
                    CreatedLinkResult(
                      key: ValueKey(_created!.id),
                      url: _created!,
                      onDismiss: () => setState(() => _created = null),
                    ),
                  ],
                  const SizedBox(height: Space.s6),
                  const RecentLinks(),
                ],
              ),
            ),
            const ResponsiveCol(medium: 4, child: OverviewStats()),
          ],
        ),
      ),
    );
  }
}
