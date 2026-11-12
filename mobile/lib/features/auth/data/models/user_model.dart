class UserModel {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? bio;
  final String preferredLanguage;
  final String? phone;
  final String? nationalId;
  final String? country;
  final bool isOnline;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.bio,
    this.preferredLanguage = 'fr',
    this.phone,
    this.nationalId,
    this.country,
    this.isOnline = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      bio: json['bio'],
      preferredLanguage: json['preferredLanguage'] ?? json['preferred_language'] ?? 'fr',
      phone: json['phone'],
      nationalId: json['nationalId'] ?? json['national_id'],
      country: json['country'],
      isOnline: json['isOnline'] ?? json['is_online'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'preferredLanguage': preferredLanguage,
      'phone': phone,
      'nationalId': nationalId,
      'country': country,
      'isOnline': isOnline,
    };
  }

  String get displayName => (firstName != null && firstName!.isNotEmpty)
      ? '$firstName ${lastName ?? ""}'.trim()
      : username;
}
