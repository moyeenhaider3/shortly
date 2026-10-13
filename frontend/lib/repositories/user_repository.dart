import '../core/network/api_client.dart';
import '../models/user_model.dart';

/// Admin-only user management (`/api/users`, guarded by `restrictTo(ADMIN)`).
class UserRepository {
  final ApiClient apiClient;

  UserRepository({required this.apiClient});

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await apiClient.dio.get('/users');
      final List list = response.data['data'];
      return list.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/users',
        data: {'name': name, 'email': email, 'password': password, 'role': role},
      );
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}
