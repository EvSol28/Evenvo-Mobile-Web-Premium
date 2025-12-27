import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
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
}
