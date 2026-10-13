import '../core/network/api_client.dart';
import '../models/url_analytics_model.dart';
import '../models/url_model.dart';

class UrlRepository {
  final ApiClient apiClient;

  UrlRepository({required this.apiClient});

  Future<List<UrlModel>> getUrls() async {
    try {
      final response = await apiClient.dio.get('/urls');
      final List list = response.data['data'];
      return list.map((item) => UrlModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UrlModel> createUrl({required String originalUrl, String? customAlias}) async {
    try {
      final response = await apiClient.dio.post(
        '/urls',
        data: {
          'originalUrl': originalUrl,
          if (customAlias != null && customAlias.trim().isNotEmpty) 'customAlias': customAlias.trim(),
        },
      );

      return UrlModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  /// Throws when the check itself fails, so the UI can tell "taken" apart
  /// from "couldn't check".
  Future<({bool available, String? reason})> checkAliasAvailability(String alias) async {
    try {
      final response = await apiClient.dio.get('/urls/check/${Uri.encodeComponent(alias)}');
      final data = response.data['data'];
      return (available: data['available'] == true, reason: data['reason'] as String?);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UrlModel> getUrlById(String id) async {
    try {
      final response = await apiClient.dio.get('/urls/$id');
      return UrlModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UrlAnalyticsModel> getUrlAnalytics(String id) async {
    try {
      final response = await apiClient.dio.get('/urls/$id/analytics');
      return UrlAnalyticsModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<void> deleteUrl(String id) async {
    try {
      await apiClient.dio.delete('/urls/$id');
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}
