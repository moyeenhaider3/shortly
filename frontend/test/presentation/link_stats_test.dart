import 'package:flutter_test/flutter_test.dart';
import 'package:url_shortener_client/models/url_model.dart';
import 'package:url_shortener_client/presentation/features/analytics/link_stats.dart';

UrlModel link(String code, {int clicks = 0, required DateTime createdAt}) => UrlModel(
  id: code,
  originalUrl: 'https://example.com',
  shortCode: code,
  shortUrl: 'http://localhost:5000/$code',
  clickCount: clicks,
  isActive: true,
  createdAt: createdAt,
);

void main() {
  // Tuesday 13 Oct 2026, so the current week started Monday 12 Oct.
  final now = DateTime(2026, 10, 13, 15);

  test('totals, average and top links', () {
    final stats = LinkStats.from([
      link('a', clicks: 10, createdAt: now),
      link('b', clicks: 30, createdAt: now),
      link('c', clicks: 0, createdAt: now),
    ], now: now);

    expect(stats.totalLinks, 3);
    expect(stats.totalClicks, 40);
    expect(stats.avgClicks, closeTo(13.33, 0.01));
    expect(stats.topLink?.shortCode, 'b');
    // Links with no clicks are left out of the ranking.
    expect(stats.topLinks.map((u) => u.shortCode), ['b', 'a']);
  });

  test('buckets links into Monday-based weeks, oldest first', () {
    final stats = LinkStats.from([
      link('this-week', createdAt: DateTime(2026, 10, 12, 9)), // Monday
      link('last-week-sun', createdAt: DateTime(2026, 10, 11, 23)), // Sunday
      link('last-week-mon', createdAt: DateTime(2026, 10, 5)),
      link('too-old', createdAt: DateTime(2025, 1, 1)),
    ], now: now);

    final weeks = stats.createdPerWeek;
    expect(weeks.length, 12);
    expect(weeks.last.start, DateTime(2026, 10, 12));
    expect(weeks.last.count, 1);
    expect(weeks[10].start, DateTime(2026, 10, 5));
    expect(weeks[10].count, 2);
    expect(weeks.fold<int>(0, (s, w) => s + w.count), 3);
  });

  test('created in the last 7 days', () {
    final stats = LinkStats.from([
      link('new', createdAt: now.subtract(const Duration(days: 6))),
      link('old', createdAt: now.subtract(const Duration(days: 8))),
    ], now: now);
    expect(stats.createdLast7Days, 1);
  });

  test('empty account', () {
    final stats = LinkStats.from(const [], now: now);
    expect((stats.totalLinks, stats.avgClicks, stats.topLink), (0, 0.0, null));
  });
}
