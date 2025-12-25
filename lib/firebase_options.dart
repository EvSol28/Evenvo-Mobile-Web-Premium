import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAPeamAYQmWeeOf8AX_J2rcQRRyKS22gr8",
    authDomain: "nocevent-20791.firebaseapp.com",
    projectId: "nocevent-20791",
    storageBucket: "nocevent-20791.firebasestorage.app",
    messagingSenderId: "669049175529",
    appId: "1:669049175529:web:2ee6dbd0510a03bd98df78",
    measurementId: "G-5M1BQ693B9",
  );
}
