import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    AppLogger.d('Notification reçue en arrière-plan: ${message.messageId}');
  } catch (e) {
    AppLogger.w('Erreur handler background FCM: $e');
  }
}

class FCMService {
  static FirebaseMessaging? get _messaging {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (e) {
      AppLogger.w('FirebaseMessaging non disponible: $e');
    }
    return null;
  }

  static Future<void> initialize() async {
    try {
      final messaging = _messaging;
      if (messaging == null) {
        AppLogger.w('FCMService non initialisé car Firebase n\'est pas actif');
        return;
      }

      // Gestionnaire en arrière-plan
      try {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } catch (e) {
        AppLogger.w('Impossible d\'enregistrer le background message handler: $e');
      }

      // Demande de permission avec timeout (requis sur Android 13+)
      try {
        final settings = await messaging
            .requestPermission(
              alert: true,
              badge: true,
              sound: true,
              provisional: false,
            )
            .timeout(const Duration(seconds: 4));

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          AppLogger.i('Permission notifications accordée');
        } else {
          AppLogger.w('Permission notifications refusée ou différée');
        }
      } catch (e) {
        AppLogger.w('Délai d\'attente permission FCM dépassé ou refusé: $e');
      }

      // Récupération asynchrone du token sans bloquer
      getToken().then((token) {
        if (token != null) {
          AppLogger.i('FCM Token de l’appareil: $token');
        }
      });

      // Écoute des messages au premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.d('Message reçu au premier plan: ${message.notification?.title}');
      });

      // Écoute de l'ouverture via notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.i('App ouverte depuis la notification: ${message.data}');
      });
    } catch (e) {
      AppLogger.w('Initialisation FCM ignorée (mode dégradé): $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return null;
      return await messaging.getToken().timeout(const Duration(seconds: 4));
    } catch (e) {
      AppLogger.w('Impossible de récupérer le token FCM (offline ou Google Play non dispo): $e');
      return null;
    }
  }
}
