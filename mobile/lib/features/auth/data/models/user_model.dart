import '../../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.displayName,
    super.avatarUrl,
    super.bio,
    super.country,
    super.phone,
    super.nationalId,
    super.preferredLanguage,
    super.isVerified,
    super.isOnline,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? json['displayName'] ?? json['full_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      bio: json['bio'],
      country: json['country'],
      phone: json['phone'],
      nationalId: json['national_id'] ?? json['nationalId'],
      preferredLanguage: json['preferred_language'] ?? json['preferredLanguage'] ?? 'fr',
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'country': country,
      'phone': phone,
      'national_id': nationalId,
      'preferred_language': preferredLanguage,
      'is_verified': isVerified,
      'is_online': isOnline,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? country,
    String? phone,
    String? nationalId,
    String? preferredLanguage,
    bool? isVerified,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
