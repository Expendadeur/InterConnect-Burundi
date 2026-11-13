import 'user_model.dart';

class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json['data'] ?? json;
    return AuthResponseModel(
      user: UserModel.fromJson(userData is Map<String, dynamic> ? userData : json),
      accessToken: json['access_token'] ?? json['token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'] ?? 3600,
    );
  }
}
