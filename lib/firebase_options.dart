// Archivo generado manualmente a partir de google-services.json
//
// Para regenerar automáticamente: dart pub global activate flutterfire_cli
// y luego ejecutar: flutterfire configure --project=mundolimpio-80a01

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    }
    // iOS no está configurado aún — no hay GoogleService-Info.plist
    throw UnsupportedError(
      'DefaultFirebaseOptions no está configurado para esta plataforma.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAxxYKRoWe1mnIigk8AqpO20Rpl4RiGJho',
    appId: '1:923159339728:android:8ae6d5e6ad57630ae134d5',
    messagingSenderId: '923159339728',
    projectId: 'mundolimpio-80a01',
    storageBucket: 'mundolimpio-80a01.firebasestorage.app',
    androidClientId: 'com.mundolimpio.app',
  );
}
