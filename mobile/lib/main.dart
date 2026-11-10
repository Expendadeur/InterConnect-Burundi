import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/services/fcm_service.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  // Capture de toutes les erreurs Dart et Flutter non interceptées
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Chargement sécurisé de l'environnement (avec fallback garanti)
    try {
      await dotenv.load(fileName: '.env');
      EnvConfig.validate();
    } catch (e) {
      AppLogger.w('Fichier .env non disponible, utilisation des valeurs par défaut: $e');
    }

    // Gestionnaire global d'erreurs Flutter (évite les fermetures intempestives)
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.e('Erreur Flutter capturée: ${details.exceptionAsString()}', error: details.exception);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.e('Erreur plateforme capturée: $error', error: error, stackTrace: stack);
      return true; // Empêche le crash natif
    };

    // 2. Lancement immédiat de l'UI (l'écran de démarrage apparaît sans blocage)
    runApp(
      const ProviderScope(
        child: InterConnectApp(),
      ),
    );

    // 3. Initialisation asynchrone des services réseau en arrière-plan
    _initBackgroundServices();
  }, (error, stackTrace) {
    AppLogger.e('Erreur non gérée dans la zone principale: $error', error: error, stackTrace: stackTrace);
  });
}

/// Initialise Firebase et Supabase de manière résiliente.
/// Si le réseau est absent, faible ou si le serveur refuse la connexion,
/// l'application continue de fonctionner sans bloquer l'utilisateur.
Future<void> _initBackgroundServices() async {
  // Initialisation de Firebase
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    AppLogger.i('Firebase initialisé avec succès');
    await FCMService.initialize();
  } catch (e) {
    AppLogger.w('Firebase non disponible au démarrage (connexion faible ou hors-ligne): $e');
  }

  // Initialisation de Supabase
  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    ).timeout(const Duration(seconds: 5));
    AppLogger.i('Supabase initialisé avec succès');
  } catch (e) {
    AppLogger.w('Supabase non disponible au démarrage (mode dégradé): $e');
  }
}
