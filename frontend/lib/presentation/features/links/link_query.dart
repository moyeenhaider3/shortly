import 'package:equatable/equatable.dart';

import '../../../models/url_model.dart';

enum LinkFilter { all, custom, generated }

enum LinkSort {
  newest('Newest'),
  oldest('Oldest'),
  mostClicks('Most clicks'),
  leastClicks('Least clicks');

  final String label;
  const LinkSort(this.label);
}

class LinkQuery extends Equatable {
  final String search;
  final LinkFilter filter;
  final LinkSort sort;
  final int page; // zero-based
  final int pageSize;

  const LinkQuery({
    this.search = '',
    this.filter = LinkFilter.all,
    this.sort = LinkSort.newest,
    this.page = 0,
    this.pageSize = 20,
  });

  bool get isFiltered => search.trim().isNotEmpty || filter != LinkFilter.all;

  LinkQuery copyWith({String? search, LinkFilter? filter, LinkSort? sort, int? page}) => LinkQuery(
    search: search ?? this.search,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    page: page ?? this.page,
    pageSize: pageSize,
  );

  @override
  List<Object?> get props => [search, filter, sort, page, pageSize];
}

class LinkPage extends Equatable {
  final List<UrlModel> items;

  /// Links matching search + filter, before paging.
  final int matched;

  /// All links, before search + filter.
  final int total;
  final int page;
  final int pageCount;
  final int pageSize;

  /// Highest click count among *all* links, so inline bars share one scale.
  final int maxClicks;

  const LinkPage({
    required this.items,
    required this.matched,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.maxClicks,
  });

  /// 1-based range shown in the footer, e.g. "21–40 of 42".
  int get rangeStart => matched == 0 ? 0 : page * pageSize + 1;
  int get rangeEnd => page * pageSize + items.length;
  bool get hasPrevious => page > 0;
  bool get hasNext => page < pageCount - 1;

  @override
  List<Object?> get props => [items, matched, total, page, pageCount, pageSize, maxClicks];
}

/// Pure search → filter → sort → page pipeline. The page index is clamped so
/// deleting the last link on a page never leaves the user on an empty page.
LinkPage applyLinkQuery(List<UrlModel> urls, LinkQuery q) {
  final needle = q.search.trim().toLowerCase();

  final matched = urls.where((u) {
    final isCustom = (u.customAlias ?? '').isNotEmpty;
    if (q.filter == LinkFilter.custom && !isCustom) return false;
    if (q.filter == LinkFilter.generated && isCustom) return false;
    if (needle.isEmpty) return true;
    return u.shortCode.toLowerCase().contains(needle) ||
        (u.customAlias ?? '').toLowerCase().contains(needle) ||
        u.originalUrl.toLowerCase().contains(needle);
  }).toList();

  int byDate(UrlModel a, UrlModel b) => a.createdAt.compareTo(b.createdAt);
  matched.sort(switch (q.sort) {
    LinkSort.newest => (a, b) => byDate(b, a),
    LinkSort.oldest => byDate,
    // Ties fall back to newest first for a stable, intuitive order.
    LinkSort.mostClicks => (a, b) => b.clickCount != a.clickCount ? b.clickCount.compareTo(a.clickCount) : byDate(b, a),
    LinkSort.leastClicks => (
      a,
      b,
    ) => a.clickCount != b.clickCount ? a.clickCount.compareTo(b.clickCount) : byDate(b, a),
  });

  final pageCount = matched.isEmpty ? 1 : (matched.length / q.pageSize).ceil();
  final page = q.page.clamp(0, pageCount - 1);
  final start = page * q.pageSize;
  final items = matched.sublist(start, (start + q.pageSize).clamp(0, matched.length));

  return LinkPage(
    items: items,
    matched: matched.length,
    total: urls.length,
    page: page,
    pageCount: pageCount,
    pageSize: q.pageSize,
    maxClicks: urls.fold(0, (m, u) => u.clickCount > m ? u.clickCount : m),
  );
}
