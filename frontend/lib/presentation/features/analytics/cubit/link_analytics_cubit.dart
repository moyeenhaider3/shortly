import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/url_analytics_model.dart';
import '../../../../models/url_model.dart';
import '../../../../repositories/url_repository.dart';
import '../../../utils/user_agent_parser.dart';

sealed class LinkAnalyticsState extends Equatable {
  const LinkAnalyticsState();
  @override
  List<Object?> get props => [];
}

class LinkAnalyticsLoading extends LinkAnalyticsState {
  const LinkAnalyticsLoading();
}

class LinkAnalyticsError extends LinkAnalyticsState {
  final String message;
  const LinkAnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

class LinkAnalyticsLoaded extends LinkAnalyticsState {
  final UrlModel link;
  final UrlAnalyticsModel analytics;

  /// Parsed once on load rather than in every build.
  final List<ParsedUserAgent> agents;

  const LinkAnalyticsLoaded(this.link, this.analytics, this.agents);

  Map<String, int> breakdown(String Function(ParsedUserAgent) key) {
    final counts = <String, int>{};
    for (final a in agents) {
      counts.update(key(a), (v) => v + 1, ifAbsent: () => 1);
    }
    return Map.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  @override
  List<Object?> get props => [link, analytics];
}

class LinkAnalyticsCubit extends Cubit<LinkAnalyticsState> {
  final UrlRepository repository;
  final String linkId;

  LinkAnalyticsCubit(this.repository, this.linkId) : super(const LinkAnalyticsLoading());

  Future<void> load() async {
    emit(const LinkAnalyticsLoading());
    try {
      final (link, analytics) = await (repository.getUrlById(linkId), repository.getUrlAnalytics(linkId)).wait;
      if (isClosed) return;
      emit(LinkAnalyticsLoaded(link, analytics, [for (final v in analytics.recentVisits) parseUserAgent(v.userAgent)]));
    } on ParallelWaitError<(UrlModel?, UrlAnalyticsModel?), (AsyncError?, AsyncError?)> catch (e) {
      if (isClosed) return;
      final error = e.errors.$1?.error ?? e.errors.$2?.error;
      emit(LinkAnalyticsError(error.toString().replaceAll('Exception: ', '')));
    }
  }
}
