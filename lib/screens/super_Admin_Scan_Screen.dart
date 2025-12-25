import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class SuperAdminScanScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const SuperAdminScanScreen({required this.eventId, required this.eventData});

  @override
  _SuperAdminScanScreenState createState() => _SuperAdminScanScreenState();
}

class _SuperAdminScanScreenState extends State<SuperAdminScanScreen>
    with TickerProviderStateMixin {
  MobileScannerController? controller;
  bool isScanning = true;
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

    _initializeScanner();
  }

  void _initializeScanner() async {
    try {
      // Configuration spécifique pour le web
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false, // Important pour les performances web
        formats: [BarcodeFormat.qrCode], // Limiter aux QR codes seulement
      );

      // Délai pour l'initialisation
      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (mounted) {
        setState(() {
          isScannerReady = true;
          hasError = false;
        });
      }
    } catch (e) {
      print('Erreur initialisation scanner: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'Impossible d\'accéder à la caméra. Vérifiez les permissions.';
          isScannerReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.stop();
    controller?.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String? qrCode) async {
    if (qrCode == null) {
      _showErrorDialog("Code QR invalide", null, null);
      return;
    }

    try {
      print("QR code scanné : $qrCode");

      Map<String, dynamic>? qrData;
      String? email;
      String? userIdFromQr;

      try {
        qrData = jsonDecode(qrCode) as Map<String, dynamic>;
        email = qrData['email'] as String?;
        userIdFromQr = qrData['userId'] as String?;
      } catch (e) {
        print("Le QR code n'est pas une chaîne JSON valide : $e");
        _showErrorDialog(
          "Ce code n'est pas un QR code valide pour cet événement. Seuls les QR codes au format JSON sont acceptés.",
          null,
          null,
        );
        return;
      }

      if (email == null || userIdFromQr == null) {
        _showErrorDialog(
          "Le QR code doit contenir un email et un userId",
          null,
          null,
        );
        return;
      }

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showErrorDialog("Utilisateur non trouvé avec cet email", null, null);
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data() as Map<String, dynamic>;

      if (userId != userIdFromQr) {
        _showErrorDialog(
          "L'userId du QR code ne correspond pas à l'utilisateur trouvé",
          null,
          null,
        );
        return;
      }

      final roleId = userData['roleId'] as String?;
      print("RoleId de l'utilisateur : $roleId");

      String roleName = 'Non défini';

      if (roleId != null) {
        final roleDoc = await FirebaseFirestore.instance
            .collection('roles')
            .doc(roleId)
            .get();

        print("Document de rôle existe : ${roleDoc.exists}");
        if (roleDoc.exists) {
          final roleData = roleDoc.data() as Map<String, dynamic>;
          print("Données du rôle : $roleData");
          roleName = roleData['name'] as String? ?? 'Non défini';
        }
      } else {
        roleName = userData['role'] as String? ?? 'Non défini';
        print("RoleId absent, utilisation du champ role : $roleName");
      }

      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (!eventDoc.exists) {
        _showErrorDialog(
          "L'événement n'existe pas dans la base de données",
          userData,
          roleName,
        );
        return;
      }

      final eventData = eventDoc.data();
      if (eventData == null) {
        _showErrorDialog(
          "Les données de l'événement sont introuvables",
          userData,
          roleName,
        );
        return;
      }

      final participants = eventData.containsKey('participants')
          ? List<String>.from(eventData['participants'] as List<dynamic>? ?? [])
          : <String>[];

      if (participants.contains(userIdFromQr)) {
        await _updatePresence(userIdFromQr, userData, roleName);
      } else {
        _showNotInvitedDialog(
          "${userData['name'] ?? 'Inconnu'} ${userData['surname'] ?? 'Inconnu'} n'est pas invité à cet événement.",
          userData,
          roleName,
        );
      }
    } catch (e) {
      print("Erreur dans _handleQRCode : $e");
      _showErrorDialog("Erreur lors du traitement : $e", null, null);
    }
  }

  Future<void> _updatePresence(
      String userId, Map<String, dynamic> userData, String roleName) async {
    try {
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId);

      final eventHistoryRef = FirebaseFirestore.instance
          .collection('event_history')
          .doc('${widget.eventId}_$userId');

      await eventRef.update({
        'presence.$userId': true,
      });

      await eventHistoryRef.set({
        'eventId': widget.eventId,
        'userId': userId,
        'userName': '${userData['name']} ${userData['surname']}',
        'role': roleName,
        'email': userData['email'] ?? 'Non disponible',
        'presence': true,
        'scanDate': FieldValue.serverTimestamp(),
        'eventName': widget.eventData['name'],
      }, SetOptions(merge: true));

      _showSuccessDialog(userData, roleName);
    } catch (e) {
      print("Erreur lors de la mise à jour de la présence : $e");
      _showErrorDialog("Erreur lors de la mise à jour : $e", userData, roleName);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> userData, String roleName) {
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
                    "Validé !",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${userData['name']} ${userData['surname']}",
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rôle : $roleName",
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.eventData['name'],
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${userData['name']} ${userData['surname']} est invité à cet événement",
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (mounted) {
                        setState(() => isScanning = true);
                        if (controller != null) {
                          controller!.start();
                        }
                      }
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

  void _showErrorDialog(
      String message, Map<String, dynamic>? userData, String? roleName) {
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
                    "Erreur",
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
                    if (roleName != null)
                      Text(
                        "Rôle : $roleName",
                        style: const TextStyle(
                          fontFamily: 'CenturyGothic',
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.eventData['name'],
                      style: const TextStyle(
                        fontFamily: 'CenturyGothic',
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
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
                      if (mounted) {
                        setState(() => isScanning = true);
                        if (controller != null) { controller!.start(); }
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

  void _showNotInvitedDialog(
      String message, Map<String, dynamic> userData, String? roleName) {
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
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Utilisateur non invité !",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${userData['name'] ?? 'Inconnu'} ${userData['surname'] ?? 'Inconnu'}",
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (roleName != null)
                    Text(
                      "Rôle : $roleName",
                      style: const TextStyle(
                        fontFamily: 'CenturyGothic',
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.eventData['name'],
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      if (mounted) {
                        setState(() => isScanning = true);
                        if (controller != null) { controller!.start(); }
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF6F6F6F),
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          Flexible(
                            child: Text(
                              "Scanner QR - ${widget.eventData['name']}",
                              style: const TextStyle(
                                fontFamily: 'CenturyGothic',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6F6F6F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.power_settings_new_rounded,
                              color: Color(0xFF6F6F6F),
                              size: 28,
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacementNamed(context, '/auth_choix');
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Color(0xFF6F6F6F),
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9F9EF).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD9F9EF).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isScanning
                                ? "Scannez le QR code d'un participant"
                                : "En attente...",
                            style: const TextStyle(
                              fontFamily: 'CenturyGothic',
                              fontSize: 18,
                              color: Color(0xFF0E6655),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF0E6655), width: 2),
                        ),
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
                                    if (isScanning && mounted) {
                                      final List<Barcode> barcodes = capture.barcodes;
                                      if (barcodes.isNotEmpty) {
                                        final String? code = barcodes.first.rawValue;
                                        if (code != null && code.isNotEmpty) {
                                          setState(() => isScanning = false);
                                          await _handleQRCode(code);
                                          if (controller != null) {
                                            controller!.stop();
                                          }
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
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final AnimationController controller;
  const AnimatedBackground({required this.controller});

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late List<Widget> shapes;

  @override
  void initState() {
    super.initState();
    shapes = [
      _buildShape(100, 50, 0.5, const Color(0xFFA2D9CE).withOpacity(0.5), 0),
      _buildShape(80, 150, 0.7, const Color(0xFFA2D9CE).withOpacity(0.4), math.pi / 4),
      _buildShape(120, 250, 0.6, const Color(0xFFA2D9CE).withOpacity(0.5), math.pi / 2),
    ];
  }

  Widget _buildShape(
      double size, double top, double opacity, Color color, double initialAngle) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Positioned(
          top: top + (50 * math.sin(widget.controller.value + initialAngle)).toDouble(),
          left: 20 + (50 * math.cos(widget.controller.value + initialAngle)).toDouble(),
          child: Transform.rotate(
            angle: widget.controller.value * 2 * math.pi + initialAngle,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size / 4),
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
