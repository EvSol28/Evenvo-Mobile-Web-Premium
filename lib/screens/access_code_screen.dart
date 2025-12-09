import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Evenvo_Mobile/screens/user_profile_screen.dart';
import 'package:Evenvo_Mobile/screens/authentication_screen.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class AccessCodeScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> userData;

  const AccessCodeScreen({
    Key? key,
    required this.eventId,
    required this.eventData,
    required this.userData,
  }) : super(key: key);

  @override
  _AccessCodeScreenState createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _backgroundController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _backgroundController.dispose();
    super.dispose();
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
        var scaleTween = Tween<double>(begin: beginScale, end: endScale).chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(scaleTween);

        // Animation de fondu
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
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

  Future<void> _verifyAccessCode() async {
    setState(() => isLoading = true);
    final enteredCode = _codeController.text.trim();
    final userId = widget.userData['id'].toString();

    try {
      final accessCodeDoc = await FirebaseFirestore.instance
          .collection('access_codes')
          .doc('${widget.eventId}_$userId')
          .get();

      if (!accessCodeDoc.exists) {
        _showErrorDialog('Code d’accès non trouvé.');
        setState(() => isLoading = false);
        return;
      }

      final accessCodeData = accessCodeDoc.data()!;
      final storedCode = accessCodeData['code'];

      if (storedCode == enteredCode) {
        await _updatePresenceInFirestore(userId, widget.eventId);

        Navigator.pushReplacement(
          context,
          _createModernRoute(
            UserProfileScreen(
              userData: widget.userData
                ..addAll({'eventId': widget.eventId, 'eventData': widget.eventData}),
            ),
          ),
        );
      } else {
        _showErrorDialog('Code d’accès incorrect.');
      }
    } catch (e) {
      print('Erreur lors de la vérification du code : $e');
      _showErrorDialog('Erreur lors de la vérification du code.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePresenceInFirestore(String userId, String eventId) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        print('Utilisateur introuvable');
        return;
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      if (userData['events'] != null && userData['events'].contains(eventId)) {
        final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
        final eventHistoryRef = FirebaseFirestore.instance
            .collection('event_history')
            .doc('${eventId}_$userId');

        await eventRef.update({'presence.$userId': true});
        await eventHistoryRef.set({
          'eventId': eventId,
          'userId': userId,
          'userName': '${userData['name']} ${userData['surname']}',
          'role': userData['role'] ?? 'Non défini',
          'email': userData['email'] ?? 'Non disponible',
          'presence': true,
          'addedDate': FieldValue.serverTimestamp(),
          'eventEndDate': widget.eventData['endDate'],
        }, SetOptions(merge: true));
        print('Présence mise à jour dans events et event_history');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la présence : $e');
      throw e;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD9F9EF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD9F9EF).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontFamily: 'CenturyGothic',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              child: Column(
                children: [
                  // Barre de navigation
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
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Entrer le code d’accès',
                              style: TextStyle(
                                fontFamily: 'CenturyGothic',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6F6F6F),
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AuthenticationScreen()),
                            );
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
                  SizedBox(height: 150), // Espace pour remonter le cadre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFd9f9ef).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFd9f9ef).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Événement : ${widget.eventData['name']}',
                                style: const TextStyle(
                                  fontFamily: 'CenturyGothic',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0E6655),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _codeController,
                                decoration: InputDecoration(
                                  labelText: 'Code d’accès',
                                  labelStyle: const TextStyle(
                                    fontFamily: 'CenturyGothic',
                                    color: Color(0xFF0E6655),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),
                              isLoading
                                  ? const CircularProgressIndicator(
                                      color: Color(0xFF0E6655))
                                  : _buildGlassButton(
                                      context,
                                      text: "Valider",
                                      onPressed: _verifyAccessCode,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: SizedBox()), // Espace flexible en bas
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bouton stylisé comme dans l'écran de choix d'authentification
  Widget _buildGlassButton(BuildContext context,
      {required String text, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5, tileMode: ui.TileMode.clamp),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Color(0xFFa2d9ce).withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Color(0xFFa2d9ce).withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFa2d9ce).withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'CenturyGothic',
                  fontSize: 16,
                  color: Color(0xFF0E6655),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  late List<Widget> shapes;

  @override
  void initState() {
    super.initState();
    shapes = [
      _buildShape(100, 50, 0.5, const Color(0xFFA2D9CE).withOpacity(0.5), 0),
      _buildShape(80, 150, 0.7, const Color(0xFFA2D9CE).withOpacity(0.4),
          math.pi / 4),
      _buildShape(120, 250, 0.6, const Color(0xFFA2D9CE).withOpacity(0.5),
          math.pi / 2),
    ];
  }

  Widget _buildShape(double size, double top, double opacity, Color color,
      double initialAngle) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Positioned(
          top:
              top + (math.sin(widget.controller.value * 2 * math.pi + initialAngle) * 20),
          left: 20 +
              (math.cos(widget.controller.value * 2 * math.pi + initialAngle) * 20),
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