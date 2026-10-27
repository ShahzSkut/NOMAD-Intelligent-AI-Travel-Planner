import 'package:equatable/equatable.dart';

// Data model for a user.
class User extends Equatable {
  final int userId;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] != null 
          ? int.parse(json['user_id'].toString()) 
          : throw const FormatException("User ID is missing or null"),

      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,

      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),

      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(), // Fallback
    );
  }

  @override
  List<Object?> get props => [userId, name, email, role, createdAt, updatedAt];
}