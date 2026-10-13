import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.authenticated(UserModel user) : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.error(String message) : this(status: AuthStatus.error, errorMessage: message);

  @override
  List<Object?> get props => [status, user, errorMessage];
}