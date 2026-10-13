import 'package:equatable/equatable.dart';

class UrlModel extends Equatable {
  final String id;
  final String originalUrl;
  final String shortCode;
  final String? customAlias;
  final String shortUrl;
  final int clickCount;
  final bool isActive;
  final DateTime createdAt;

  const UrlModel({
    required this.id,
    required this.originalUrl,
    required this.shortCode,
    this.customAlias,
    required this.shortUrl,
    required this.clickCount,
    required this.isActive,
    required this.createdAt,
  });

  factory UrlModel.fromJson(Map<String, dynamic> json) {
    return UrlModel(
      id: json['id'] ?? json['_id'] ?? '',
      originalUrl: json['originalUrl'] ?? '',
      shortCode: json['shortCode'] ?? '',
      customAlias: json['customAlias'],
      shortUrl: json['shortUrl'] ?? '',
      clickCount: json['clickCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, originalUrl, shortCode, customAlias, shortUrl, clickCount, isActive, createdAt];
}