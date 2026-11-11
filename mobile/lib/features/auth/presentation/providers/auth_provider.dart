import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/fcm_service.dart';
import '../../data/models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated([String? error]) => AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'jwt_access_token');
    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final res = await _apiClient.dio.get('/users/me');
      final user = UserModel.fromJson(res.data);
      state = AuthState.authenticated(user);

      // Met à jour le token FCM en arrière-plan
      _syncFCMToken();
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> _syncFCMToken() async {
    try {
      final fcmToken = await FCMService.getToken();
      if (fcmToken != null) {
        await _apiClient.dio.patch('/users/me', data: {
          'fcmToken': fcmToken,
        });
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final res = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      await _storage.write(key: 'jwt_access_token', value: res.data['accessToken']);
      await _storage.write(key: 'jwt_refresh_token', value: res.data['refreshToken']);

      final user = UserModel.fromJson(res.data['user']);
      state = AuthState.authenticated(user);

      await _syncFCMToken();
      return true;
    } catch (e) {
      state = AuthState.unauthenticated('Identifiants invalides ou serveur indisponible');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? firstName,
    String? lastName,
    String? preferredLanguage,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? nationalId,
    String? country,
  }) async {
    state = AuthState.loading();
    try {
      final res = await _apiClient.dio.post('/auth/register', data: {
        'email': email,
        'username': username,
        'password': password,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId,
        if (country != null && country.isNotEmpty) 'country': country,
      });

      await _storage.write(key: 'jwt_access_token', value: res.data['accessToken']);
      await _storage.write(key: 'jwt_refresh_token', value: res.data['refreshToken']);

      final user = UserModel.fromJson(res.data['user']);
      state = AuthState.authenticated(user);

      await _syncFCMToken();
      return true;
    } catch (e) {
      String errorMsg = "Échec de l'inscription.";
      if (e is DioException) {
        if (e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            final msg = data['message'];
            errorMsg = msg is List ? msg.join('\n') : msg.toString();
          } else {
            errorMsg = "Erreur serveur (${e.response?.statusCode}): ${e.response?.statusMessage}";
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout ||
                   e.type == DioExceptionType.connectionError) {
          errorMsg = "Impossible de contacter le serveur Render. Vérifiez votre connexion Internet ou réveillez le serveur.";
        } else {
          errorMsg = "Erreur réseau: ${e.message}";
        }
      } else {
        errorMsg = "Erreur: $e";
      }
      state = AuthState.unauthenticated(errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
