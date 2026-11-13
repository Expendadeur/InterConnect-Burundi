class UserEntity {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? country;
  final String? phone;
  final String? nationalId;
  final String preferredLanguage;
  final bool isVerified;
  final bool isOnline;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.country,
    this.phone,
    this.nationalId,
    this.preferredLanguage = 'fr',
    this.isVerified = false,
    this.isOnline = false,
    required this.createdAt,
  });
}
