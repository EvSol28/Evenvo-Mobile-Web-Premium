import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  MobileScannerController controller = MobileScannerController();
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
    _requestCameraPermission();
  }

  // Demande la permission dès l'ouverture de la page + popup si besoin
Future<void> _requestCameraPermission() async {
  // On affiche TOUJOURS le popup explicatif au démarrage de la page
  // pour être sûr que l'utilisateur voit le message clair et appuie sur le bouton
  if (mounted) {
    _showCameraPermissionPopup();
  }
}

  // Popup personnalisé pour demander la permission
  void _showCameraPermissionPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur doit choisir
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.95),
        title: const Text(
          "Accès à la caméra requis",
          style: TextStyle(
            fontFamily: 'CenturyGothic',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0E6655),
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Pour scanner les QR codes, cette application a besoin d'accéder à votre caméra.\n\nAppuyez sur \"Autoriser la caméra\" pour continuer.",
          style: TextStyle(
            fontFamily: 'CenturyGothic',
            fontSize: 16,
            color: Color(0xFF0E6655),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Ferme le popup
              final status = await Permission.camera.request();
              if (status.isGranted) {
                setState(() {
                  cameraPermissionGranted = true;
                });
              } else {
                // Si refusé, montre le dialog classique avec ouverture paramètres
                _showPermissionDeniedDialog();
              }
            },
            child: const Text(
              "Autoriser la caméra",
              style: TextStyle(
                fontFamily: 'CenturyGothic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E6655),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission refusée"),
        content: const Text(
            "Vous avez refusé l'accès à la caméra. Pour scanner les QR codes, veuillez l'autoriser dans les paramètres."),
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
                                  cameraPermissionGranted
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 250,
                                            height: 250,
                                            child: Stack(
                                              children: [
                                                MobileScanner(
                                                  controller: controller,
                                                  onDetect: (BarcodeCapture capture) async {
                                                    final List<Barcode> barcodes = capture.barcodes;
                                                    if (barcodes.isNotEmpty && !isProcessing) {
                                                      final String? code = barcodes.first.rawValue;
                                                      if (code != null) {
                                                        isProcessing = true;
                                                        await _handleScannedCode(code, context);
                                                      }
                                                    }
                                                  },
                                                ),
                                                QRScannerOverlay(
                                                  borderColor: const Color(0xFF0E6655),
                                                  borderRadius: 8,
                                                  borderLength: 20,
                                                  borderWidth: 6,
                                                  cutOutSize: 230,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 250,
                                          height: 250,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
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
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 16),
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

  Future<void> _handleScannedCode(String scannedCode, BuildContext context) async {
    await controller.stop();
    try {
      final qrData = jsonDecode(scannedCode);
      print('QR Data: $qrData');

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: qrData['name'])
          .where('surname', isEqualTo: qrData['surname'])
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();
        print('User Data: $userData');

        final roleName = qrData['role'];
        if (roleName == null) {
          _showErrorDialog("Aucun rôle spécifié dans le QR code", userData);
          return;
        }

        final roleSnapshot = await FirebaseFirestore.instance
            .collection('roles')
            .where('name', isEqualTo: roleName)
            .limit(1)
            .get();

        if (roleSnapshot.docs.isNotEmpty) {
          final roleData = roleSnapshot.docs.first.data();
          print('Role Data: $roleData');

          if (roleData['MobileAccessGlobal'] == true) {
            await FirebaseAuth.instance.signInAnonymously();
            _showSuccessDialog(userData, roleName);
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
                      controller.start();
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
                      controller.start();
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
    controller.dispose();
    _backgroundController.dispose();
    super.dispose();
  }
}

// Overlay personnalisé
class QRScannerOverlay extends StatelessWidget {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QRScannerOverlay({
    Key? key,
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QRScannerOverlayPainter(
        borderColor: borderColor,
        borderRadius: borderRadius,
        borderLength: borderLength,
        borderWidth: borderWidth,
        cutOutSize: cutOutSize,
      ),
    );
  }
}

class _QRScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  _QRScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final rect = Rect.fromLTWH(
      (size.width - cutOutSize) / 2,
      (size.height - cutOutSize) / 2,
      cutOutSize,
      cutOutSize,
    );

    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));

    final cornerLength = borderLength;

    path.moveTo(rect.left, rect.top + cornerLength);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.left + cornerLength, rect.top);

    path.moveTo(rect.right - cornerLength, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + cornerLength);

    path.moveTo(rect.right, rect.bottom - cornerLength);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right - cornerLength, rect.bottom);

    path.moveTo(rect.left + cornerLength, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.bottom - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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