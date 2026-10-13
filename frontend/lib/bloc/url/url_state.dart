import 'package:equatable/equatable.dart';

import '../../models/url_model.dart';

enum UrlAction { fetch, create, delete }

/// Every state carries the current list, so the UI never blanks while a
/// one-off action result (success/error) is being shown.
abstract class UrlState extends Equatable {
  const UrlState();
  List<UrlModel> get urls => const [];
  @override
  List<Object?> get props => [urls];
}

class UrlInitial extends UrlState {}

class UrlLoading extends UrlState {
  @override
  final List<UrlModel> urls;
  const UrlLoading([this.urls = const []]);
}

class UrlLoaded extends UrlState {
  @override
  final List<UrlModel> urls;
  const UrlLoaded(this.urls);
}

class UrlCreating extends UrlState {
  @override
  final List<UrlModel> urls;
  const UrlCreating(this.urls);
}

class UrlActionSuccess extends UrlState {
  final UrlAction action;
  final String message;
  @override
  final List<UrlModel> urls;
  final UrlModel? created;
  const UrlActionSuccess(this.action, this.message, this.urls, {this.created});
  @override
  List<Object?> get props => [action, message, urls, created];
}

class UrlError extends UrlState {
  final UrlAction action;
  final String message;
  @override
  final List<UrlModel> urls;
  const UrlError(this.action, this.message, this.urls);
  @override
  List<Object?> get props => [action, message, urls];
}
