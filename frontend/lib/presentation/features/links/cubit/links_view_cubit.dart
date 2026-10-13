import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/url_model.dart';
import '../link_query.dart';

class LinksViewState extends Equatable {
  final LinkQuery query;
  final LinkPage page;

  const LinksViewState(this.query, this.page);

  @override
  List<Object?> get props => [query, page];
}

/// Screen-local view state for the links table: search, filter, sort, page.
/// The derived page is computed here when inputs change, never in `build()`.
class LinksViewCubit extends Cubit<LinksViewState> {
  List<UrlModel> _source;

  LinksViewCubit(List<UrlModel> source)
    : _source = source,
      super(LinksViewState(const LinkQuery(), applyLinkQuery(source, const LinkQuery())));

  void _apply(LinkQuery q) => emit(LinksViewState(q, applyLinkQuery(_source, q)));

  void updateSource(List<UrlModel> urls) {
    _source = urls;
    _apply(state.query);
  }

  void search(String value) {
    if (value == state.query.search) return;
    _apply(state.query.copyWith(search: value, page: 0));
  }

  void setFilter(LinkFilter filter) => _apply(state.query.copyWith(filter: filter, page: 0));
  void setSort(LinkSort sort) => _apply(state.query.copyWith(sort: sort, page: 0));
  void nextPage() => _apply(state.query.copyWith(page: state.page.page + 1));
  void previousPage() => _apply(state.query.copyWith(page: state.page.page - 1));
  void clearFilters() => _apply(const LinkQuery().copyWith(sort: state.query.sort));
}
