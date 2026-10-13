import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../repositories/url_repository.dart';
import '../../../utils/link_rules.dart';

enum AliasStatus { idle, invalid, checking, available, taken, unknown }

class AliasCheckState extends Equatable {
  final AliasStatus status;
  final String? message;

  const AliasCheckState(this.status, [this.message]);

  /// Submitting is blocked only when we *know* the alias won't work.
  bool get blocksSubmit => status == AliasStatus.invalid || status == AliasStatus.taken;

  @override
  List<Object?> get props => [status, message];
}

/// Two-stage alias validation: instant client rules, then a debounced server
/// check. A request counter drops out-of-order responses.
class AliasCheckCubit extends Cubit<AliasCheckState> {
  final UrlRepository repository;
  final Duration debounce;
  Timer? _timer;
  int _requestId = 0;

  AliasCheckCubit(this.repository, {this.debounce = const Duration(milliseconds: 400)})
    : super(const AliasCheckState(AliasStatus.idle));

  void onChanged(String raw) {
    _timer?.cancel();
    final id = ++_requestId;
    final alias = raw.trim().toLowerCase();

    if (alias.isEmpty) return emit(const AliasCheckState(AliasStatus.idle));

    final error = LinkRules.aliasError(alias);
    if (error != null) return emit(AliasCheckState(AliasStatus.invalid, error));

    emit(const AliasCheckState(AliasStatus.checking));
    _timer = Timer(debounce, () => _check(alias, id));
  }

  Future<void> _check(String alias, int id) async {
    try {
      final result = await repository.checkAliasAvailability(alias);
      if (isClosed || id != _requestId) return;
      emit(
        result.available
            ? const AliasCheckState(AliasStatus.available, 'Available')
            : AliasCheckState(AliasStatus.taken, result.reason ?? 'Already taken'),
      );
    } catch (_) {
      if (isClosed || id != _requestId) return;
      emit(const AliasCheckState(AliasStatus.unknown, "Couldn't check availability"));
    }
  }

  void reset() {
    _timer?.cancel();
    _requestId++;
    emit(const AliasCheckState(AliasStatus.idle));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
