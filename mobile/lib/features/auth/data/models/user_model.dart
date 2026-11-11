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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      preferredLanguage: json['preferredLanguage'] ?? 'fr',
      phone: json['phone'],
      nationalId: json['nationalId'],
      country: json['country'],
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
    };
  }

  String get displayName => (firstName != null && firstName!.isNotEmpty)
      ? '$firstName ${lastName ?? ""}'.trim()
      : username;
}

