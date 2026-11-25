import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Android usa google-services.json; as demais plataformas usam dart-defines.
abstract final class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  static bool get _androidNativo =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get configurado =>
      _androidNativo ||
      [apiKey, appId, senderId, projectId].every((valor) => valor.isNotEmpty);

  static String? _opcional(String valor) => valor.isEmpty ? null : valor;

  static FirebaseOptions? get options => _androidNativo
      ? null
      : FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
          authDomain: _opcional(
            const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
          ),
          storageBucket: _opcional(
            const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
          ),
          iosBundleId: _opcional(
            const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
          ),
        );

  static String get workerUrl => Uri.base
      .resolve('firebase-messaging-sw.js')
      .replace(
        queryParameters: {
          'apiKey': apiKey,
          'appId': appId,
          'messagingSenderId': senderId,
          'projectId': projectId,
        },
      )
      .toString();
}
