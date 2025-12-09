import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/Authentification_choix_screen.dart';
import 'screens/Authentication_screen.dart';
import 'screens/Authentification_super_admin_screen.dart';
import 'screens/super_admin_event_selection_screen.dart';
import 'screens/access_code_screen.dart'; // Ajout de l'import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/super_admin_events': (context) => SuperAdminEventSelectionScreen(),
        '/access_code': (context) => AccessCodeScreen(
          eventId: ModalRoute.of(context)!.settings.arguments as String,
          eventData: {}, // Vous devrez passer les données correctes via Navigator
          userData: {}, // Idem
        ), // Route ajoutée (note : ajustez les arguments selon le contexte)
      },
    );
  }
}