import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:Evenvo_Mobile/screens/authentification_super_admin_screen.dart';
import 'package:Evenvo_Mobile/screens/authentication_screen.dart';

class AuthentificationChoixScreen extends StatefulWidget {
  @override
  _AuthentificationChoixScreenState createState() =>
      _AuthentificationChoixScreenState();
}

class _AuthentificationChoixScreenState
    extends State<AuthentificationChoixScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _controller.forward();
    _backgroundController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
              bottom: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1),
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                      sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    padding: EdgeInsets.all(20),
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 30),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFd9f9ef).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            Color(0xFFd9f9ef).withOpacity(0.5),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFFd9f9ef)
                                              .withOpacity(0.1),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        ClipOval(
                                          child: Image.asset(
                                            'assets/LogoClient.png',
                                            width: 130,
                                            height: 130,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(height: 30),
                                        Text(
                                          "Bienvenue sur ēvenvo",
                                          style: TextStyle(
                                            fontFamily: 'CenturyGothic',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0E6655),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 15),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Text(
                                            "ēvenvo est votre solution idéale pour organiser, gérer et participer à des événements professionnels ou personnels en toute simplicité",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'CenturyGothic',
                                              fontSize: 14,
                                              color: Color(0xFF0E6655)
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 50),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                child: _buildGlassButton(
                                                  context,
                                                  text: "Utilisateurs",
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      _createModernRoute(
                                                          AuthenticationScreen()),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                child: _buildGlassButton(
                                                  context,
                                                  text: "Super Admin",
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      _createModernRoute(
                                                          AuthentificationSuperAdminScreen()),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1),
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
      {required String text, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                  fontSize: 14,
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

  Widget _buildShape(
      double size, double top, double opacity, Color color, double initialAngle) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Positioned(
          top: top +
              (math.sin(widget.controller.value * 2 * math.pi + initialAngle) *
                  20).toDouble(),
          left: 20 +
              (math.cos(widget.controller.value * 2 * math.pi + initialAngle) *
                  20).toDouble(),
          child: Transform.rotate(
            angle: widget.controller.value * 2 * math.pi + initialAngle,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(
                    size / (4 + (math.sin(widget.controller.value * math.pi) * 2).toDouble())),
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
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: shapes,
    );
  }
}