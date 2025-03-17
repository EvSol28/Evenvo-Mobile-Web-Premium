import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;

class SuperAdminScanScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const SuperAdminScanScreen({required this.eventId, required this.eventData});

  @override
  _SuperAdminScanScreenState createState() => _SuperAdminScanScreenState();
}

class _SuperAdminScanScreenState extends State<SuperAdminScanScreen>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;
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

  @override
  void dispose() {
    controller?.pauseCamera();
    controller?.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

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
        title: Text("Permission requise"),
        content: Text("L'accès à la caméra est nécessaire pour scanner les QR codes."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text("Ouvrir les paramètres"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    if (!mounted) return;
    setState(() {
      this.controller = controller;
    });
    print("QRViewController créé");
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanning || !mounted) return;

      setState(() => isScanning = false);
      print("Code scanné : ${scanData.code}");
      await _handleQRCode(scanData.code);
      if (mounted) {
        controller.pauseCamera();
      }
    }, onError: (error) {
      print("Erreur dans le flux de scan : $error");
      _showErrorDialog("Erreur de scan : $error", null);
    });
  }

  Future<void> _handleQRCode(String? qrCode) async {
    if (qrCode == null) {
      _showErrorDialog("Code QR invalide", null);
      return;
    }

    try {
      print("QR code scanné : $qrCode");
      Map<String, dynamic> qrData = jsonDecode(qrCode) as Map<String, dynamic>;
      final email = qrData['email'] as String?;

      if (email == null) {
        _showErrorDialog("Email manquant dans le QR code", null);
        return;
      }

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showErrorDialog("Utilisateur non trouvé avec cet email", null);
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data() as Map<String, dynamic>;

      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();
      final participants = List<String>.from(eventDoc['participants'] ?? []);

      if (participants.contains(userId)) {
        await _updatePresence(userId, userData);
        _showSuccessDialog(userData);
      } else {
        _showErrorDialog(
          "${userData['name']} ${userData['surname']} n'est pas invité à cet événement",
          userData,
        );
      }
    } catch (e) {
      print("Erreur dans _handleQRCode : $e");
      _showErrorDialog("Erreur lors du traitement: $e", null);
    }
  }

  Future<void> _updatePresence(String userId, Map<String, dynamic> userData) async {
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
        'role': userData['role'] ?? 'Non défini',
        'email': userData['email'] ?? 'Non disponible',
        'presence': true,
        'scanDate': FieldValue.serverTimestamp(),
        'eventName': widget.eventData['name'],
      }, SetOptions(merge: true));
    } catch (e) {
      print("Erreur lors de la mise à jour de la présence: $e");
      throw e;
    }
  }

  void _showSuccessDialog(Map<String, dynamic> userData) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: Duration(milliseconds: 300),
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
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFD9F9EF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFFD9F9EF).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFD9F9EF).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF0E6655), size: 60),
                  SizedBox(height: 20),
                  Text(
                    "Validé !",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "${userData['name']} ${userData['surname']}",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.eventData['name'],
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655).withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "${userData['name']} ${userData['surname']} est invité à cet événement",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Color(0xFF0E6655).withOpacity(0.8),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (mounted) {
                        setState(() => isScanning = true);
                        controller?.resumeCamera();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Color(0xFF0E6655),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
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
      transitionDuration: Duration(milliseconds: 300),
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
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFD9F9EF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFFD9F9EF).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFD9F9EF).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close, color: Colors.white, size: 40),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Non validé",
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  if (userData != null) ...[
                    Text(
                      "${userData['name']} ${userData['surname']}",
                      style: TextStyle(
                        fontFamily: 'CenturyGothic',
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.eventData['name'],
                      style: TextStyle(
                        fontFamily: 'CenturyGothic',
                        color: Colors.red.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                  SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (mounted) {
                        setState(() => isScanning = true);
                        controller?.resumeCamera();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
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
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF6F6F6F),
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Retour à l'écran précédent
                          },
                        ),
                        Flexible(
                          child: Text(
                            "Scanner QR - ${widget.eventData['name']}",
                            style: TextStyle(
                              fontFamily: 'CenturyGothic',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6F6F6F),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
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
                  Divider(
                    color: Color(0xFF6F6F6F),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFFD9F9EF).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFFD9F9EF).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isScanning
                              ? "Scannez le QR code d'un participant"
                              : "En attente...",
                          style: TextStyle(
                            fontFamily: 'CenturyGothic',
                            fontSize: 18,
                            color: Color(0xFF0E6655),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: cameraPermissionGranted
                          ? Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Color(0xFF0E6655), width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: QRView(
                                  key: qrKey,
                                  onQRViewCreated: _onQRViewCreated,
                                  overlay: QrScannerOverlayShape(
                                    borderColor: Color(0xFF0E6655),
                                    borderRadius: 10,
                                    borderLength: 30,
                                    borderWidth: 10,
                                    cutOutSize: 250,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              child: Center(
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
                    ),
                  ),
                  SizedBox(height: 20),
                ],
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

  AnimatedBackground({required this.controller});

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
      _buildShape(100, 50, 0.5, Color(0xFFA2D9CE).withOpacity(0.5), 0),
      _buildShape(80, 150, 0.7, Color(0xFFA2D9CE).withOpacity(0.4), math.pi / 4),
      _buildShape(120, 250, 0.6, Color(0xFFA2D9CE).withOpacity(0.5), math.pi / 2),
    ];
  }

  Widget _buildShape(double size, double top, double opacity, Color color, double initialAngle) {
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