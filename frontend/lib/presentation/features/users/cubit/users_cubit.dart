import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/user_model.dart';
import '../../../../repositories/user_repository.dart';

enum UsersStatus { loading, loaded, error }

class UsersState extends Equatable {
  final UsersStatus status;
  final List<UserModel> users;
  final String? error;

  const UsersState({this.status = UsersStatus.loading, this.users = const [], this.error});

  int get adminCount => users.where((u) => u.isAdmin).length;

  @override
  List<Object?> get props => [status, users, error];
}

class UsersCubit extends Cubit<UsersState> {
  final UserRepository repository;

  UsersCubit(this.repository) : super(const UsersState());

  Future<void> load() async {
    emit(UsersState(status: UsersStatus.loading, users: state.users));
    try {
      final users = await repository.getUsers();
      if (!isClosed) emit(UsersState(status: UsersStatus.loaded, users: users));
    } catch (e) {
      if (!isClosed) emit(UsersState(status: UsersStatus.error, users: state.users, error: _message(e)));
    }
  }

  /// Returns the created user. Throws with a readable message so the dialog
  /// can show it inline and keep the form filled.
  Future<UserModel> create({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final user = await repository.createUser(name: name, email: email, password: password, role: role);
      if (!isClosed) emit(UsersState(status: UsersStatus.loaded, users: [user, ...state.users]));
      return user;
    } catch (e) {
      throw _message(e);
    }
  }

  String _message(Object e) => e.toString().replaceAll('Exception: ', '');
}
