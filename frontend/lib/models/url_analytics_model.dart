import 'package:equatable/equatable.dart';

class VisitModel extends Equatable {
  final DateTime visitedAt;
  final String? ip;
  final String? userAgent;

  const VisitModel({required this.visitedAt, this.ip, this.userAgent});

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      visitedAt: DateTime.tryParse(json['visitedAt'] ?? '')?.toLocal() ?? DateTime.now(),
      ip: json['ip'],
      userAgent: json['userAgent'],
    );
  }

  @override
  List<Object?> get props => [visitedAt, ip, userAgent];
}

/// Response of `GET /urls/:id/analytics`. The backend returns only the
/// last 10 visits, newest first.
class UrlAnalyticsModel extends Equatable {
  final String id;
  final int totalClicks;
  final DateTime? lastVisitedAt;
  final DateTime createdAt;
  final List<VisitModel> recentVisits;

  const UrlAnalyticsModel({
    required this.id,
    required this.totalClicks,
    required this.lastVisitedAt,
    required this.createdAt,
    required this.recentVisits,
  });

  factory UrlAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final List visits = json['recentVisits'] ?? const [];
    return UrlAnalyticsModel(
      id: json['id'] ?? '',
      totalClicks: json['totalClicks'] ?? 0,
      lastVisitedAt: DateTime.tryParse(json['lastVisitedAt'] ?? '')?.toLocal(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
      recentVisits: visits.map((v) => VisitModel.fromJson(v)).toList(),
    );
  }

  @override
  List<Object?> get props => [id, totalClicks, lastVisitedAt, createdAt, recentVisits];
}
