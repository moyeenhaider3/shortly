import 'package:equatable/equatable.dart';

abstract class UrlEvent extends Equatable {
  const UrlEvent();
  @override
  List<Object?> get props => [];
}

class FetchUrls extends UrlEvent {}

/// Drops cached links, e.g. on logout so the next user never sees them.
class UrlsCleared extends UrlEvent {}

class CreateUrlRequested extends UrlEvent {
  final String originalUrl;
  final String? customAlias;

  const CreateUrlRequested({required this.originalUrl, this.customAlias});
  @override
  List<Object?> get props => [originalUrl, customAlias];
}

class DeleteUrlRequested extends UrlEvent {
  final String urlId;

  const DeleteUrlRequested(this.urlId);
  @override
  List<Object?> get props => [urlId];
}
