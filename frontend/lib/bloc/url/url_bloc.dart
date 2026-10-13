import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/url_repository.dart';
import '../../models/url_model.dart';
import 'url_event.dart';
import 'url_state.dart';

class UrlBloc extends Bloc<UrlEvent, UrlState> {
  final UrlRepository urlRepository;
  List<UrlModel> _cachedUrls = [];

  UrlBloc({required this.urlRepository}) : super(UrlInitial()) {
    on<FetchUrls>(_onFetchUrls);
    on<CreateUrlRequested>(_onCreateUrlRequested);
    on<DeleteUrlRequested>(_onDeleteUrlRequested);
    on<UrlsCleared>((event, emit) {
      _cachedUrls = [];
      emit(UrlInitial());
    });
  }

  List<UrlModel> get _snapshot => List.unmodifiable(_cachedUrls);

  String _message(Object e) => e.toString().replaceAll('Exception: ', '');

  Future<void> _onFetchUrls(FetchUrls event, Emitter<UrlState> emit) async {
    emit(UrlLoading(_snapshot));
    try {
      _cachedUrls = await urlRepository.getUrls();
      emit(UrlLoaded(_snapshot));
    } catch (e) {
      emit(UrlError(UrlAction.fetch, _message(e), _snapshot));
    }
  }

  Future<void> _onCreateUrlRequested(CreateUrlRequested event, Emitter<UrlState> emit) async {
    emit(UrlCreating(_snapshot));
    try {
      final created = await urlRepository.createUrl(originalUrl: event.originalUrl, customAlias: event.customAlias);
      _cachedUrls.insert(0, created);
      emit(UrlActionSuccess(UrlAction.create, 'Short link created', _snapshot, created: created));
      emit(UrlLoaded(_snapshot));
    } catch (e) {
      emit(UrlError(UrlAction.create, _message(e), _snapshot));
      emit(UrlLoaded(_snapshot));
    }
  }

  Future<void> _onDeleteUrlRequested(DeleteUrlRequested event, Emitter<UrlState> emit) async {
    try {
      await urlRepository.deleteUrl(event.urlId);
      _cachedUrls.removeWhere((item) => item.id == event.urlId);
      emit(UrlActionSuccess(UrlAction.delete, 'Link deactivated', _snapshot));
      emit(UrlLoaded(_snapshot));
    } catch (e) {
      emit(UrlError(UrlAction.delete, _message(e), _snapshot));
      emit(UrlLoaded(_snapshot));
    }
  }
}
