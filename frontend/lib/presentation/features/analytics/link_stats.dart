import 'package:equatable/equatable.dart';

import '../../../models/url_model.dart';

/// Account-level numbers derived client-side from `GET /urls`.
class LinkStats extends Equatable {
  final int totalLinks;
  final int totalClicks;
  final double avgClicks;
  final int createdLast7Days;
  final UrlModel? topLink;

  /// Up to 10 links ordered by clicks (desc), for the "Top links" BarList.
  final List<UrlModel> topLinks;

  /// Links created per week, oldest → newest, for the last [weeks] weeks.
  final List<WeekBucket> createdPerWeek;

  const LinkStats({
    required this.totalLinks,
    required this.totalClicks,
    required this.avgClicks,
    required this.createdLast7Days,
    required this.topLink,
    required this.topLinks,
    required this.createdPerWeek,
  });

  factory LinkStats.from(List<UrlModel> urls, {DateTime? now, int weeks = 12}) {
    final today = now ?? DateTime.now();
    final totalClicks = urls.fold<int>(0, (s, u) => s + u.clickCount);

    final ranked = [...urls]..sort((a, b) => b.clickCount.compareTo(a.clickCount));
    final topLinks = ranked.where((u) => u.clickCount > 0).take(10).toList();

    // Weeks start on Monday, local time.
    final startOfThisWeek = DateTime(today.year, today.month, today.day).subtract(Duration(days: today.weekday - 1));
    final buckets = [
      for (var i = weeks - 1; i >= 0; i--) WeekBucket(startOfThisWeek.subtract(Duration(days: 7 * i)), 0),
    ];
    final counts = List<int>.filled(weeks, 0);
    for (final u in urls) {
      for (var i = weeks - 1; i >= 0; i--) {
        if (!u.createdAt.isBefore(buckets[i].start)) {
          counts[i]++;
          break;
        }
      }
    }

    return LinkStats(
      totalLinks: urls.length,
      totalClicks: totalClicks,
      avgClicks: urls.isEmpty ? 0 : totalClicks / urls.length,
      createdLast7Days: urls.where((u) => today.difference(u.createdAt).inDays < 7).length,
      topLink: topLinks.isEmpty ? null : topLinks.first,
      topLinks: topLinks,
      createdPerWeek: [for (var i = 0; i < weeks; i++) WeekBucket(buckets[i].start, counts[i])],
    );
  }

  @override
  List<Object?> get props => [totalLinks, totalClicks, avgClicks, createdLast7Days, topLink, topLinks, createdPerWeek];
}

class WeekBucket extends Equatable {
  final DateTime start;
  final int count;
  const WeekBucket(this.start, this.count);

  @override
  List<Object?> get props => [start, count];
}
