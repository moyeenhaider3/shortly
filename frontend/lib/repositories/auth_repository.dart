import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SharedPreferences prefs;

  AuthRepository({required this.apiClient, required this.prefs});

  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final token = response.data['data']['token'];
      await prefs.setString(ApiClient.tokenKey, token);
      return UserModel.fromJson(response.data['data']['user']);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['data']['token'];
      await prefs.setString(ApiClient.tokenKey, token);
      return UserModel.fromJson(response.data['data']['user']);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = prefs.getString(ApiClient.tokenKey);
      if (token == null) return null;

      final response = await apiClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data['data']);
    } catch (_) {
      await prefs.remove(ApiClient.tokenKey);
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await prefs.remove(ApiClient.tokenKey);
    }
  }
}