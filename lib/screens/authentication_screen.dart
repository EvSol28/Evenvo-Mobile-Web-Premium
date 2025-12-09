import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:Evenvo_Mobile/screens/event_selection_screen.dart';
import 'package:Evenvo_Mobile/screens/authentification_choix_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  bool cameraPermissionGranted = false;

  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _checkCameraPermission();
  }

  // Vérifier les permissions de la caméra
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        cameraPermissionGranted = true;
      });
      print("Permission caméra accordée");
    } else {
      setState(() {
        cameraPermissionGranted = false;
      });
      print("Permission caméra refusée");
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission requise"),
        content: const Text(
            "L'accès à la caméra est nécessaire pour scanner les QR codes."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Ouvrir les paramètres"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

  // Transition moderne avec fondu et mise à l'échelle
  Route _createModernRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const beginScale = 0.95; // Légère réduction initiale
        const endScale = 1.0; // Taille normale
        const curve = Curves.easeInOut;

        // Animation de mise à l'échelle
        var scaleTween = Tween<double>(begin: beginScale, end: endScale)
            .chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(scaleTween);

        // Animation de fondu
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
                    padding: const EdgeInsets.only(
                        top: 8.0, left: 16.0, right: 16.0),
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
                                    color: const Color(0xFFd9f9ef)
                                        .withOpacity(0.1),
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
                                  cameraPermissionGranted
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 250,
                                            height: 250,
                                            child: QRView(
                                              key: qrKey,
                                              onQRViewCreated: _onQRViewCreated,
                                              overlay: QrScannerOverlayShape(
                                                borderColor:
                                                    const Color(0xFF0E6655),
                                                borderRadius: 8,
                                                borderLength: 20,
                                                borderWidth: 6,
                                                cutOutSize: 230,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 250,
                                          height: 250,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: Colors.grey.withOpacity(0.2),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "Permission caméra requise",
                                              style: TextStyle(
                                                fontFamily: 'CenturyGothic',
                                                color: Color(0xFF0E6655),
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      // Utiliser la transition moderne pour le retour
                                      Navigator.pushReplacement(
                                        context,
                                        _createModernRoute(
                                            AuthentificationChoixScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Retour',
                                      style: TextStyle(
                                        color: Color(0xFF0E6655)
                                            .withOpacity(0.8),
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

  void _onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);
    controller.scannedDataStream.listen((scanData) async {
      if (!isProcessing && scanData.code != null) {
        isProcessing = true;
        await _handleScannedCode(scanData.code!, context);
      }
    }, onError: (error) {
      print("Erreur dans le flux de scan : $error");
      _showErrorDialog("Erreur de scan : $error", null);
    });
  }

  Future<void> _handleScannedCode(String scannedCode, BuildContext context) async {
    controller?.pauseCamera();
    try {
      final qrData = jsonDecode(scannedCode);
      print('QR Data: $qrData'); // Débogage

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: qrData['name'])
          .where('surname', isEqualTo: qrData['surname'])
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();
        print('User Data: $userData'); // Débogage

        final roleName = qrData['role'];
        if (roleName == null) {
          _showErrorDialog("Aucun rôle spécifié dans le QR code", userData);
          return;
        }
        print('Role Name from QR: $roleName'); // Débogage

        final roleSnapshot = await FirebaseFirestore.instance
            .collection('roles')
            .where('name', isEqualTo: roleName)
            .limit(1)
            .get();

        if (roleSnapshot.docs.isNotEmpty) {
          final roleData = roleSnapshot.docs.first.data();
          print('Role Data: $roleData'); // Débogage

          if (roleData['MobileAccessGlobal'] == true) {
            await FirebaseAuth.instance.signInAnonymously(); // Connexion anonyme activée
            _showSuccessDialog(userData, roleName);
          } else {
            _showErrorDialog(
                "Votre rôle n'est pas autorisé à accéder à l'application", userData);
          }
        } else {
          _showErrorDialog("Rôle non trouvé dans la base", userData);
          print('No role found for name: $roleName'); // Débogage
        }
      } else {
        _showErrorDialog("Cet utilisateur n'existe pas en base", null);
        print(
            'No user found for name: ${qrData['name']}, surname: ${qrData['surname']}'); // Débogage
      }
    } catch (e) {
      _showErrorDialog("Problème avec le QR code: $e", null);
      print('Error: $e'); // Débogage
    } finally {
      isProcessing = false;
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
                  const Icon(Icons.check_circle,
                      color: Color(0xFF0E6655), size: 60),
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
                      controller?.resumeCamera();
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
                      controller?.resumeCamera();
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

  @override
  void dispose() {
    controller?.dispose();
    _backgroundController.dispose();
    super.dispose();
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