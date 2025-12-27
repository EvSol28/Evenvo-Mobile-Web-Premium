import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Ajout pour Firebase
import 'package:flutter/foundation.dart';
import 'firebase_options.dart'; // Import des options Firebase
import 'screens/Authentification_choix_screen.dart';
import 'screens/Authentication_screen.dart';
import 'screens/Authentification_super_admin_screen.dart';
import 'screens/super_admin_event_selection_screen.dart'; // Import manquant

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialisation de Firebase avec les bonnes options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialisé avec succès');
    print('Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    print('API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey}');
  } catch (e) {
    print('Erreur initialisation Firebase: $e');
  }
  
  if (kIsWeb) {
    // Pour le web, on peut garder les # dans les URLs pour éviter les problèmes de routing
    // usePathUrlStrategy(); // Commenté temporairement
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Evenvo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/auth_choix',
      routes: {
        '/auth_choix': (context) => AuthentificationChoixScreen(),
        '/auth': (context) => AuthenticationScreen(),
        '/auth_super_admin': (context) => AuthentificationSuperAdminScreen(),
        '/super_admin_events': (context) => SuperAdminEventSelectionScreen(), // Ajout de la route
      },
    );
  }
}