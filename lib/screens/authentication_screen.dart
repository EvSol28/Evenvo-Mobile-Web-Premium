import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:Evenvo_Mobile/screens/event_selection_screen.dart';
import 'package:Evenvo_Mobile/screens/authentification_choix_screen.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'dart:html' as html show window;

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  MobileScannerController? controller;
  bool isProcessing = false;
  bool isScannerReady = false;
  bool hasError = false;
  String? errorMessage;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _initializeAuth();
    _initializeScanner();
  }

  void _initializeAuth() async {
    try {
      // S'authentifier dès le démarrage
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        print('Authentification anonyme réussie au démarrage');
      }
    } catch (e) {
      print('Erreur d\'authentification au démarrage: $e');
    }
  }

  void _initializeScanner() async {
    try {
      print('🔍 Initialisation du scanner...');
      
      // Vérification spécifique pour le web
      if (kIsWeb) {
        print('🌐 Plateforme web détectée');
        
        // Vérifier si les APIs de caméra sont disponibles
        if (!_isWebCameraSupported()) {
          throw Exception('Les APIs de caméra ne sont pas supportées sur ce navigateur');
        }
      }
      
      // Configuration spécifique pour le web
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false, // Important pour les performances web
        formats: [BarcodeFormat.qrCode], // Limiter aux QR codes seulement
      );

      // Délai plus long pour l'initialisation web
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        setState(() {
          isScannerReady = true;
          hasError = false;
        });
        print('✅ Scanner initialisé avec succès');
      }
    } catch (e) {
      print('❌ Erreur initialisation scanner: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = kIsWeb 
            ? 'Caméra non accessible sur le web. Essayez:\n• Autoriser la caméra dans les paramètres du navigateur\n• Utiliser HTTPS\n• Essayer un autre navigateur (Chrome/Firefox)'
            : 'Impossible d\'accéder à la caméra. Vérifiez les permissions.';
          isScannerReady = false;
        });
      }
    }
  }

  bool _isWebCameraSupported() {
    // Cette fonction sera toujours true pour simplifier, 
    // mais on peut ajouter des vérifications plus sophistiquées
    return true;
  }

  @override
  void dispose() {
    controller?.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Route _createModernRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const beginScale = 0.95;
        const endScale = 1.0;
        const curve = Curves.easeInOut;
        var scaleTween = Tween<double>(begin: beginScale, end: endScale)
            .chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(scaleTween);
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(fadeTween);
        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            AnimatedBackground(controller: _backgroundController),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 100,
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe8f6f3).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFd9f9ef).withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFd9f9ef).withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Authentification Utilisateur',
                                    style: TextStyle(
                                      fontFamily: 'CenturyGothic',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0E6655),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: 300,
                                    height: 300,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Stack(
                                        children: [
                                          // Scanner ou message d'erreur
                                          if (hasError)
                                            _buildErrorView()
                                          else if (isScannerReady && controller != null)
                                            MobileScanner(
                                              controller: controller!,
                                              onDetect: (BarcodeCapture capture) async {
                                                if (!isProcessing) {
                                                  final List<Barcode> barcodes = capture.barcodes;
                                                  if (barcodes.isNotEmpty) {
                                                    final String? code = barcodes.first.rawValue;
                                                    if (code != null && code.isNotEmpty) {
                                                      setState(() {
                                                        isProcessing = true;
                                                      });
                                                      await _handleScannedCode(code, context);
                                                    }
                                                  }
                                                }
                                              },
                                            )
                                          else
                                            _buildLoadingView(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        _createModernRoute(AuthentificationChoixScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Retour',
                                      style: TextStyle(
                                        color: Color(0xFF0E6655).withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF0E6655),
              strokeWidth: 6,
            ),
            SizedBox(height: 24),
            Text(
              "Activation de la caméra...",
              style: TextStyle(
                fontFamily: 'CenturyGothic',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.red.withOpacity(0.1),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Erreur caméra',
                style: const TextStyle(
                  fontFamily: 'CenturyGothic',
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '💡 Solutions pour le web:',
                        style: TextStyle(
                          fontFamily: 'CenturyGothic',
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Cliquez sur l\'icône 🔒 dans la barre d\'adresse\n'
                        '2. Autorisez l\'accès à la caméra\n'
                        '3. Rafraîchissez la page (F5)\n'
                        '4. Essayez Chrome ou Firefox si le problème persiste',
                        style: TextStyle(
                          fontFamily: 'CenturyGothic',
                          color: Colors.blue,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        hasError = false;
                        isScannerReady = false;
                      });
                      _initializeScanner();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E6655),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                  if (kIsWeb)
                    ElevatedButton(
                      onPressed: () {
                        // Rafraîchir la page
                        html.window.location.reload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Rafraîchir'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleScannedCode(String scannedCode, BuildContext context) async {
    if (controller != null) {
      await controller!.stop();
    }
    
    try {
      final qrData = jsonDecode(scannedCode);
      print('QR Data: $qrData');

      // Tentative de lecture avec gestion d'erreur de permissions
      DocumentSnapshot? userDoc;
      QuerySnapshot? userSnapshot;
      
      try {
        userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: qrData['name'])
            .where('surname', isEqualTo: qrData['surname'])
            .limit(1)
            .get();
      } catch (permissionError) {
        print('Erreur de permissions Firestore: $permissionError');
        
        // Authentification d'abord, puis retry
        try {
          await FirebaseAuth.instance.signInAnonymously();
          print('Authentification anonyme réussie, retry...');
          
          // Retry après authentification
          userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('name', isEqualTo: qrData['name'])
              .where('surname', isEqualTo: qrData['surname'])
              .limit(1)
              .get();
        } catch (authError) {
          print('Erreur d\'authentification: $authError');
          _showErrorDialog("Erreur d'authentification: ${authError.toString()}", null);
          return;
        }
      }

      if (userSnapshot != null && userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        print('User Data: $userData');

        final roleName = qrData['role'];
        if (roleName == null) {
          _showErrorDialog("Aucun rôle spécifié dans le QR code", userData);
          return;
        }

        QuerySnapshot? roleSnapshot;
        try {
          roleSnapshot = await FirebaseFirestore.instance
              .collection('roles')
              .where('name', isEqualTo: roleName)
              .limit(1)
              .get();
        } catch (roleError) {
          print('Erreur lecture rôle: $roleError');
          _showErrorDialog("Erreur d'accès aux rôles: ${roleError.toString()}", userData);
          return;
        }

        if (roleSnapshot.docs.isNotEmpty) {
          final roleData = roleSnapshot.docs.first.data() as Map<String, dynamic>;
          print('Role Data: $roleData');

          if (roleData['MobileAccessGlobal'] == true) {
            // Authentification avec un token personnalisé basé sur l'utilisateur
            try {
              if (FirebaseAuth.instance.currentUser == null) {
                await FirebaseAuth.instance.signInAnonymously();
              }
              // Stocker les données utilisateur localement pour les permissions
              _showSuccessDialog(userData, roleName);
            } catch (authError) {
              print('Erreur d\'authentification: $authError');
              _showErrorDialog("Erreur d'authentification: $authError", userData);
              return;
            }
          } else {
            _showErrorDialog(
                "Votre rôle n'est pas autorisé à accéder à l'application", userData);
          }
        } else {
          _showErrorDialog("Rôle non trouvé dans la base", userData);
          print('No role found for name: $roleName');
        }
      } else {
        _showErrorDialog("Cet utilisateur n'existe pas en base", null);
        print('No user found for name: ${qrData['name']}, surname: ${qrData['surname']}');
      }
    } catch (e) {
      _showErrorDialog("Problème avec le QR code: $e", null);
      print('Error: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _navigateToEventSelection(Map<String, dynamic> userData) {
    Navigator.pushReplacement(
      context,
      _createModernRoute(EventSelectionScreen(userData: userData)),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> userData, String role) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD9F9EF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD9F9EF).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD9F9EF).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF0E6655), size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Bienvenue !",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${userData['surname']} ${userData['name']}",
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Profil : $role",
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEventSelection(userData);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E6655),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Continuer",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'CenturyGothic',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  void _showErrorDialog(String message, Map<String, dynamic>? userData) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD9F9EF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD9F9EF).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD9F9EF).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Non validé",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (userData != null) ...[
                    Text(
                      "${userData['name']} ${userData['surname']}",
                      style: const TextStyle(
                        fontFamily: 'CenturyGothic',
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (controller != null) {
                        controller!.start(); // Reprend la caméra après erreur
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Continuer",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'CenturyGothic',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final AnimationController controller;
  const AnimatedBackground({required this.controller});

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  late List<Widget> shapes;

  @override
  void initState() {
    super.initState();
    shapes = [
      _buildShape(100, 50, 0.5, const Color(0xFFA2D9CE).withOpacity(0.5), 0),
      _buildShape(
          80, 150, 0.7, const Color(0xFFA2D9CE).withOpacity(0.4), math.pi / 4),
      _buildShape(
          120, 250, 0.6, const Color(0xFFA2D9CE).withOpacity(0.5), math.pi / 2),
    ];
  }

  Widget _buildShape(
      double size, double top, double opacity, Color color, double initialAngle) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Positioned(
          top: top +
              (math.sin(widget.controller.value * 2 * math.pi + initialAngle) *
                  20),
          left: 20 +
              (math.cos(widget.controller.value * 2 * math.pi + initialAngle) *
                  20),
          child: Transform.rotate(
            angle: widget.controller.value * 2 * math.pi + initialAngle,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(
                    size / (4 + (math.sin(widget.controller.value * math.pi) * 2))),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: shapes);
  }
}