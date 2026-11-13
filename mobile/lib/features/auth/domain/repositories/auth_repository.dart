import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<({UserEntity user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  });

  Future<({UserEntity user, String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String? avatarUrl,
    String? phone,
    String? nationalId,
    String? country,
    String preferredLanguage,
  });

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();

  Future<String?> refreshToken(String refreshToken);
}
