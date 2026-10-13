import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Overridden at build time: flutter build web --dart-define=API_BASE_URL=https://...
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000/api');
  static const String tokenKey = 'jwt_token';

  /// Host (and port, if any) of the backend, derived from [baseUrl] — e.g.
  /// "localhost:5000" in dev or "shortly-dgxi.onrender.com" in production.
  /// The domain short links live on.
  static String get publicHost {
    final uri = Uri.parse(baseUrl);
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  final SharedPreferences prefs;
  late final Dio dio;

  ApiClient(this.prefs) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )..interceptors.addAll([
        // Injects JWT Bearer token on every outgoing request
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final token = prefs.getString(tokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) async {
            if (e.response?.statusCode == 401) {
              await prefs.remove(tokenKey);
            }
            return handler.next(e);
          },
        ),
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          requestBody: true,
          responseBody: true,
        ),
      ]);
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        return error.response?.data['message'] ?? 'Server error occurred';
      }
      return error.message ?? 'Network connection error';
    }
    return error.toString();
  }
}