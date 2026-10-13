import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  static const roleAdmin = 'ADMIN';
  static const roleNormal = 'NORMAL';

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == roleAdmin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? roleNormal,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, createdAt];
}