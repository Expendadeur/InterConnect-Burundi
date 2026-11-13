import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient apiClient;

  AuthRemoteDatasource({required this.apiClient});

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const AppException(message: 'Unknown error during login');
  }

  Future<AuthResponseModel> register({
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
    try {
      final response = await apiClient.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'username': username,
          'display_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (phone != null) 'phone': phone,
          if (nationalId != null) 'national_id': nationalId,
          if (country != null) 'country': country,
          'preferred_language': preferredLanguage,
        },
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const AppException(message: 'Unknown error during register');
  }

  Future<UserModel> getMe() async {
    try {
      final response = await apiClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const AppException(message: 'Unknown error getting profile');
  }

  Never _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        throw UnauthorizedException(
          message: e.response?.data?['message'] ?? 'Non autorisé',
        );
      case 404:
        throw NotFoundException(message: 'Ressource introuvable');
      case 422:
        throw ValidationException(
          message: e.response?.data?['message'] ?? 'Données invalides',
        );
      case 500:
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Erreur serveur',
        );
      default:
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown) {
          throw const NetworkException();
        }
        throw AppException(
          message: e.response?.data?['message'] ?? e.message ?? 'Erreur inconnue',
          statusCode: e.response?.statusCode,
        );
    }
  }
}
