import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp().timeout(const Duration(seconds: 2));
    }
    AppLogger.d('FCM Background: ${message.messageId}');
  } catch (_) {}
}

class FCMService {
  static FirebaseMessaging? get _messaging {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Initialise FCM de manière 100% NON-BLOQUANTE.
  /// Ne bloque jamais le démarrage de l'appli ni les requêtes de l'utilisateur.
  static Future<void> initialize() async {
    // Exécuté dans un Future différé sans bloquer le thread principal
    unawaited(
      Future(() async {
        try {
          final messaging = _messaging;
          if (messaging == null) return;

          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

          // Demande de permission avec un timeout très court (1 seconde)
          await messaging
              .requestPermission(
                alert: true,
                badge: true,
                sound: true,
                provisional: true,
              )
              .timeout(const Duration(seconds: 1));

          // Écoute des messages en avant-plan
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            AppLogger.d('Message reçu: ${message.notification?.title}');
          });
        } catch (_) {
          // Tolérance aux pannes silencieuse
        }
      }),
    );
  }

  /// Récupération ultra-rapide du token FCM avec timeout de 1.5 seconde.
  /// Si le service Google Play n'est pas prêt, retourne null immédiatement.
  static Future<String?> getToken() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return null;
      return await messaging.getToken().timeout(const Duration(milliseconds: 1500));
    } catch (_) {
      return null;
    }
  }
}
