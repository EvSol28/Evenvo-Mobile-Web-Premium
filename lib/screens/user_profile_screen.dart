import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Evenvo_Mobile/screens/vote_screen.dart';
import 'package:Evenvo_Mobile/screens/dynamic_vote_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Evenvo_Mobile/screens/authentication_screen.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  bool voteEnabled = false;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _fetchVoteStatus();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
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

  Future<void> _fetchVoteStatus() async {
    try {
      // Récupérer le rôle de l'utilisateur
      final userRoleName = widget.userData['role'] as String?;
      if (userRoleName == null) {
        print('Rôle non défini pour l\'utilisateur ${widget.userData['id']}');
        setState(() {
          voteEnabled = false;
        });
        return;
      }

      // Récupérer l'ID du rôle dans la collection 'roles'
      final roleQuery = await FirebaseFirestore.instance
          .collection('roles')
          .where('name', isEqualTo: userRoleName)
          .limit(1)
          .get();

      if (roleQuery.docs.isEmpty) {
        print('Rôle $userRoleName non trouvé dans la collection roles');
        setState(() {
          voteEnabled = false;
        });
        return;
      }

      final roleId = roleQuery.docs.first.id;

      // Récupérer les données de l'événement
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.userData['eventId'])
          .get();

      if (!eventDoc.exists) {
        print('Événement ${widget.userData['eventId']} non trouvé');
        setState(() {
          voteEnabled = false;
        });
        return;
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final roleVoteSettings = eventData['roleVoteSettings'] as Map<String, dynamic>?;

      if (roleVoteSettings != null && roleVoteSettings.containsKey(roleId)) {
        final voteEnabledForRole = roleVoteSettings[roleId]['voteEnabled'] as bool? ?? false;
        setState(() {
          voteEnabled = voteEnabledForRole;
        });
        print('Utilisateur ${widget.userData['id']} avec rôle $userRoleName peut voter : $voteEnabled');
      } else {
        print('Aucun paramètre de vote trouvé pour le rôle $roleId dans l\'événement ${widget.userData['eventId']}');
        setState(() {
          voteEnabled = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération de voteEnabled: $e");
      setState(() {
        voteEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String civility = widget.userData['civility'] ?? '';
    String avatarImage =
        civility == 'Mme' ? 'assets/female_avatar.png' : 'assets/male_avatar.png';

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            AnimatedBackground(controller: _backgroundController),
            SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                "Profil Utilisateur",
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
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFFd9f9ef).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFFd9f9ef).withOpacity(0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFd9f9ef).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 80,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: AssetImage(avatarImage),
                                ),
                                SizedBox(height: 30),
                                Text(
                                  "$civility. ${widget.userData['name'] ?? 'Non renseigné'} ${widget.userData['surname'] ?? 'Non renseigné'}",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0E6655),
                                    fontFamily: 'CenturyGothic',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.work,
                                      size: 20,
                                      color: Color(0xFF0E6655),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "${widget.userData['role'] ?? 'Non renseigné'}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF0E6655).withOpacity(0.8),
                                        fontFamily: 'CenturyGothic',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    // Bouton "Voter" affiché dynamiquement selon voteEnabled
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      child: _buildGlassButton(
                        context,
                        text: "Vote Simple",
                        onPressed: voteEnabled
                            ? () {
                                Navigator.push(
                                  context,
                                  _createModernRoute(
                                    VoteScreen(
                                      userId: widget.userData['id'].toString(),
                                      eventId: widget.userData['eventId'].toString(),
                                      canVote: voteEnabled,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                    // Bouton "Formulaires de Vote" pour les formulaires dynamiques
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      child: _buildGlassButton(
                        context,
                        text: "Formulaires de Vote",
                        onPressed: voteEnabled
                            ? () {
                                Navigator.push(
                                  context,
                                  _createModernRoute(
                                    DynamicVoteScreen(
                                      userId: widget.userData['id'].toString(),
                                      eventId: widget.userData['eventId'].toString(),
                                      canVote: voteEnabled,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context,
      {required String text, required VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5, tileMode: ui.TileMode.clamp),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: onPressed != null
                  ? Color(0xFFa2d9ce).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: onPressed != null
                    ? Color(0xFFa2d9ce).withOpacity(0.5)
                    : Colors.grey.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: onPressed != null
                      ? Color(0xFFa2d9ce).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
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
      _buildShape(100, 50, 0.5, Color(0xFFA2D9CE).withOpacity(0.5), 0),
      _buildShape(80, 150, 0.7, Color(0xFFA2D9CE).withOpacity(0.4), math.pi / 4),
      _buildShape(120, 250, 0.6, Color(0xFFA2D9CE).withOpacity(0.5), math.pi / 2),
    ];
  }

  Widget _buildShape(
      double size, double top, double opacity, Color color, double initialAngle) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Positioned(
          top: top + (math.sin(widget.controller.value * 2 * math.pi + initialAngle) * 20),
          left: 20 + (math.cos(widget.controller.value * 2 * math.pi + initialAngle) * 20),
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