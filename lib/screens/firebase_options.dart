import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Logique pour différentes plateformes
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      // Autres plateformes...
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'votre-api-key',
    appId: 'votre-app-id',
    messagingSenderId: 'votre-sender-id',
    projectId: 'votre-project-id',
    storageBucket: 'votre-storage-bucket',
  );
}