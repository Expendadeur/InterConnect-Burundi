import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/fcm_service.dart';
import '../../data/models/user_model.dart';

// CORRECTION : apiClientProvider etait defini ici ET dans core/network/api_client.dart,
// ce qui provoquait l'erreur "imported from both". La definition dupliquee est supprimee ;
// on re-exporte celle d'api_client.dart pour que les fichiers qui n'importent que
// auth_provider.dart continuent d'y avoir acces (meme declaration = pas d'ambiguite).
export '../../../../core/network/api_client.dart' show apiClientProvider;

// CORRECTION : les clés de stockage étaient 'jwt_access_token' / 'jwt_refresh_token',
// alors qu'AuthInterceptor et ApiClient lisent 'access_token' / 'refresh_token'.
// Résultat : aucun en-tête Bearer n'était envoyé après la connexion (erreurs 401).
// Les clés sont maintenant alignées.
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

  // CORRECTION : getters utilises par app_router.dart (isAuthenticated / isLoading).
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated([String? error]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final res = await _apiClient.dio
          .get('/users/me')
          .timeout(const Duration(seconds: 8));
      final user = UserModel.fromJson(res.data);
      state = AuthState.authenticated(user);

      // FCM en tâche de fond ultra-rapide et totalement détachée
      unawaited(_syncFCMToken().catchError((_) {}));
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> _syncFCMToken() async {
    try {
      final fcmToken = await FCMService.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _apiClient.dio
            .patch('/users/me', data: {'fcmToken': fcmToken})
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final res = await _apiClient.dio
          .post('/auth/login', data: {
            'email': email,
            'password': password,
          })
          // CORRECTION : 12 s était trop court pour un backend Render qui se réveille
          // (démarrage à froid d'environ 1 minute) -> délai porté à 60 s.
          .timeout(const Duration(seconds: 60));

      await _storage.write(
          key: 'access_token', value: res.data['accessToken']);
      await _storage.write(
          key: 'refresh_token', value: res.data['refreshToken']);

      final user = UserModel.fromJson(res.data['user']);
      state = AuthState.authenticated(user);

      // FCM exécuté en arrière-plan immédiat SANS AUCUN BLOCAGE
      unawaited(_syncFCMToken().catchError((_) {}));
      return true;
    } on TimeoutException {
      state = AuthState.unauthenticated(
          'Délai de connexion dépassé. Vérifiez votre connexion Internet.');
      return false;
    } catch (e) {
      String errorMsg = 'Identifiants invalides ou serveur indisponible.';
      if (e is DioException) {
        if (e.response?.data != null && e.response!.data is Map) {
          final data = e.response!.data as Map;
          final msg = data['message'] ?? (data['error'] is Map ? data['error']['message'] : null);
          if (msg != null) {
            errorMsg = msg is List ? msg.join('\n') : msg.toString();
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg = 'Serveur injoignable. Vérifiez la connexion Internet.';
        }
      }
      state = AuthState.unauthenticated(errorMsg);
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
      final res = await _apiClient.dio
          .post('/auth/register', data: {
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
          })
          // CORRECTION : 12 s était trop court pour un backend Render qui se réveille
          // (démarrage à froid d'environ 1 minute) -> délai porté à 60 s.
          .timeout(const Duration(seconds: 60));

      await _storage.write(
          key: 'access_token', value: res.data['accessToken']);
      await _storage.write(
          key: 'refresh_token', value: res.data['refreshToken']);

      final user = UserModel.fromJson(res.data['user']);
      state = AuthState.authenticated(user);

      // FCM en arrière-plan sans bloquer
      unawaited(_syncFCMToken().catchError((_) {}));
      return true;
    } on TimeoutException {
      state = AuthState.unauthenticated(
          'Délai dépassé. Vérifiez votre connexion Internet.');
      return false;
    } catch (e) {
      String errorMsg = "Échec de l'inscription.";
      if (e is DioException) {
        if (e.response?.data != null && e.response!.data is Map) {
          final data = e.response!.data as Map;
          dynamic errorObj = data['error'];
          dynamic messageObj = data['message'];

          if (errorObj is Map && errorObj['message'] != null) {
            final m = errorObj['message'];
            errorMsg = m is List ? m.join('\n') : m.toString();
          } else if (messageObj != null) {
            errorMsg = messageObj is List
                ? messageObj.join('\n')
                : messageObj.toString();
          } else if (errorObj is String) {
            errorMsg = errorObj;
          } else if (e.response?.statusCode == 409) {
            errorMsg =
                "Email ou nom d'utilisateur déjà utilisé. Choisissez-en un autre.";
          } else {
            errorMsg =
                "Erreur (${e.response?.statusCode}) lors de l'inscription.";
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg =
              "Impossible de contacter le serveur. Vérifiez votre connexion Internet.";
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
      await _apiClient.dio.post('/auth/logout').timeout(const Duration(seconds: 3));
    } catch (_) {}
    await _storage.deleteAll();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});