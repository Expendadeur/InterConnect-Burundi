import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final FlutterSecureStorage secureStorage;

  const AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.secureStorage,
  });

  @override
  Future<({UserEntity user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDatasource.login(
      email: email,
      password: password,
    );

    await secureStorage.write(key: 'access_token', value: response.accessToken);
    await secureStorage.write(key: 'refresh_token', value: response.refreshToken);

    return (
      user: response.user,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
  }

  @override
  Future<({UserEntity user, String accessToken, String refreshToken})> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String? avatarUrl,
    String? phone,
    String? nationalId,
    String? country,
    String preferredLanguage = 'fr',
  }) async {
    final response = await remoteDatasource.register(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      phone: phone,
      nationalId: nationalId,
      country: country,
      preferredLanguage: preferredLanguage,
    );

    await secureStorage.write(key: 'access_token', value: response.accessToken);
    await secureStorage.write(key: 'refresh_token', value: response.refreshToken);

    return (
      user: response.user,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: 'access_token');
    await secureStorage.delete(key: 'refresh_token');
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await secureStorage.read(key: 'access_token');
    if (token == null) return null;
    try {
      return await remoteDatasource.getMe();
    } on UnauthorizedException {
      await secureStorage.delete(key: 'access_token');
      await secureStorage.delete(key: 'refresh_token');
      return null;
    }
  }

  @override
  Future<String?> refreshToken(String token) async {
    return secureStorage.read(key: 'access_token');
  }
}
