// lib/models/user.dart

class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? role;
  final bool? active;
  final DateTime createdAt;
  final DateTime? updatedAt;
  String? profilePhotoUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role,
    this.active,
    required this.createdAt,
    this.updatedAt,
    this.profilePhotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      role: json['role'],
      active: json['active'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      profilePhotoUrl: json['profilePhotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  User copyWith({
    String? name,
    String? phone,
    String? profilePhotoUrl,
  }) {
    return User(
      id: this.id,
      name: name ?? this.name,
      email: this.email,
      phone: phone ?? this.phone,
      role: this.role,
      active: this.active,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }
}
