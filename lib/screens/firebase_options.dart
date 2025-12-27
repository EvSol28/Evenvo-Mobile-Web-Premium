import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDpLgR7glKjSIsgT66wSxMn8FhX_4hddLM",
    authDomain: "evenvo-ba568.firebaseapp.com",
    projectId: "evenvo-ba568",
    storageBucket: "evenvo-ba568.firebasestorage.app",
    messagingSenderId: "647067484176",
    appId: "1:647067484176:web:c9d3ec3e2d116a53528a95",
    measurementId: "G-429KZ0X69X",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDpLgR7glKjSIsgT66wSxMn8FhX_4hddLM",
    authDomain: "evenvo-ba568.firebaseapp.com",
    projectId: "evenvo-ba568",
    storageBucket: "evenvo-ba568.firebasestorage.app",
    messagingSenderId: "647067484176",
    appId: "1:647067484176:android:ANDROID_APP_ID",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDpLgR7glKjSIsgT66wSxMn8FhX_4hddLM",
    authDomain: "evenvo-ba568.firebaseapp.com",
    projectId: "evenvo-ba568",
    storageBucket: "evenvo-ba568.firebasestorage.app",
    messagingSenderId: "647067484176",
    appId: "1:647067484176:ios:IOS_APP_ID",
  );
}