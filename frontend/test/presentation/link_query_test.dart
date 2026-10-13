import 'package:flutter_test/flutter_test.dart';
import 'package:url_shortener_client/models/url_model.dart';
import 'package:url_shortener_client/presentation/features/links/link_query.dart';

UrlModel link(String code, {String? alias, int clicks = 0, int daysAgo = 0, String url = 'https://example.com'}) =>
    UrlModel(
      id: code,
      originalUrl: url,
      shortCode: code,
      customAlias: alias,
      shortUrl: 'http://localhost:5000/$code',
      clickCount: clicks,
      isActive: true,
      createdAt: DateTime(2026, 10, 13).subtract(Duration(days: daysAgo)),
    );

void main() {
  final urls = [
    link('abc123', clicks: 5, daysAgo: 1, url: 'https://github.com/acme'),
    link('promo', alias: 'promo', clicks: 40, daysAgo: 3),
    link('xyz789', clicks: 5, daysAgo: 0),
    link('docs', alias: 'docs', clicks: 0, daysAgo: 10, url: 'https://docs.flutter.dev'),
  ];

  List<String> codes(LinkPage p) => p.items.map((u) => u.shortCode).toList();

  test('defaults to newest first', () {
    expect(codes(applyLinkQuery(urls, const LinkQuery())), ['xyz789', 'abc123', 'promo', 'docs']);
  });

  test('search matches code, alias and destination case-insensitively', () {
    expect(codes(applyLinkQuery(urls, const LinkQuery(search: 'GITHUB'))), ['abc123']);
    expect(codes(applyLinkQuery(urls, const LinkQuery(search: 'pro'))), ['promo']);
    expect(codes(applyLinkQuery(urls, const LinkQuery(search: '  flutter '))), ['docs']);
  });

  test('filters custom vs generated', () {
    expect(codes(applyLinkQuery(urls, const LinkQuery(filter: LinkFilter.custom))), ['promo', 'docs']);
    expect(codes(applyLinkQuery(urls, const LinkQuery(filter: LinkFilter.generated))), ['xyz789', 'abc123']);
  });

  test('click sorts break ties by newest', () {
    expect(codes(applyLinkQuery(urls, const LinkQuery(sort: LinkSort.mostClicks))), [
      'promo',
      'xyz789',
      'abc123',
      'docs',
    ]);
    expect(codes(applyLinkQuery(urls, const LinkQuery(sort: LinkSort.leastClicks))), [
      'docs',
      'xyz789',
      'abc123',
      'promo',
    ]);
  });

  test('pages and reports the visible range', () {
    final many = [for (var i = 0; i < 45; i++) link('c$i', daysAgo: i)];
    final p2 = applyLinkQuery(many, const LinkQuery(page: 1));
    expect(p2.items.length, 20);
    expect((p2.rangeStart, p2.rangeEnd, p2.matched, p2.pageCount), (21, 40, 45, 3));
    expect(p2.hasPrevious && p2.hasNext, isTrue);

    final last = applyLinkQuery(many, const LinkQuery(page: 2));
    expect((last.rangeStart, last.rangeEnd, last.hasNext), (41, 45, false));
  });

  test('clamps an out-of-range page (e.g. after deleting the last row)', () {
    final p = applyLinkQuery(urls, const LinkQuery(page: 5));
    expect(p.page, 0);
    expect(p.items.length, 4);
  });

  test('maxClicks spans all links, not just the filtered ones', () {
    final p = applyLinkQuery(urls, const LinkQuery(filter: LinkFilter.generated));
    expect(p.maxClicks, 40);
  });

  test('empty input yields an empty first page', () {
    final p = applyLinkQuery(const [], const LinkQuery());
    expect((p.items.length, p.matched, p.pageCount, p.rangeStart), (0, 0, 1, 0));
  });
}
