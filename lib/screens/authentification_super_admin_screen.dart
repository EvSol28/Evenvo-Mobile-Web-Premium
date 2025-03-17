import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class AuthentificationSuperAdminScreen extends StatefulWidget {
  @override
  _AuthentificationSuperAdminScreenState createState() =>
      _AuthentificationSuperAdminScreenState();
}

class _AuthentificationSuperAdminScreenState
    extends State<AuthentificationSuperAdminScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _loginSuperAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('super_admin')
            .doc(userCredential.user?.uid)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          var data = snapshot.data() as Map<String, dynamic>?;
          if (data == null || data['role'] != 'Super Admin') {
            throw Exception('Cet utilisateur n\'est pas un super administrateur.');
          }
        } else {
          throw Exception('Aucun super administrateur trouvé avec cet UID.');
        }

        Navigator.pushReplacementNamed(context, '/super_admin_events');
      } on FirebaseAuthException catch (e) {
        _showErrorDialog('Erreur de connexion : ${e.message}');
      } catch (e) {
        _showErrorDialog('Une erreur inattendue est survenue : $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 50),
                  SizedBox(height: 15),
                  Text(
                    'Erreur de connexion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  _buildGlassButton(
                    text: 'OK',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({required String text, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 160,
            padding: EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Color(0xFFa2d9ce).withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0xFFa2d9ce).withOpacity(0.5)),
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
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFe8f6f3).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(0xFFd9f9ef).withOpacity(0.5),
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
                                        SizedBox(height: 20),
                                        Text(
                                          'Authentification Super Admin',
										  
                                          style: TextStyle(
										  fontFamily: 'CenturyGothic',
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0E6655),
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: TextStyle(color: Color(0xFF0E6655)),
                                          decoration: InputDecoration(
                                            labelText: 'Adresse Email',
                                            labelStyle: TextStyle(color: Color(0xFF0E6655).withOpacity(0.8)),
                                            prefixIcon: Icon(Icons.email, color: Color(0xFF0E6655)),
                                            filled: true,
                                            fillColor: Color(0xFFa2d9ce).withOpacity(0.2),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                              return 'Veuillez entrer un email valide';
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 20),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscureText,
                                          style: TextStyle(color: Color(0xFF0E6655)),
                                          decoration: InputDecoration(
                                            labelText: 'Mot de passe',
                                            labelStyle: TextStyle(color: Color(0xFF0E6655).withOpacity(0.8)),
                                            prefixIcon: Icon(Icons.lock, color: Color(0xFF0E6655)),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                                color: Color(0xFF0E6655),
                                              ),
                                              onPressed: () => setState(() => _obscureText = !_obscureText),
                                            ),
                                            filled: true,
                                            fillColor: Color(0xFFa2d9ce).withOpacity(0.2),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
                                            if (value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 30),
                                        _isLoading
                                            ? CircularProgressIndicator(color: Color(0xFF0E6655))
                                            : _buildGlassButton(
                                                text: 'Connexion',
                                                onPressed: _loginSuperAdmin,
                                              ),
                                        SizedBox(height: 20),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
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
}

class AnimatedBackground extends StatefulWidget {
  final AnimationController controller;

  AnimatedBackground({required this.controller});

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

  Widget _buildShape(double size, double top, double opacity, Color color, double initialAngle) {
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
                borderRadius: BorderRadius.circular(size / (4 + (math.sin(widget.controller.value * math.pi) * 2))),
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