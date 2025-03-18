import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication_screen.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class VoteScreen extends StatefulWidget {
  final String userId;
  final String eventId;

  const VoteScreen({Key? key, required this.userId, required this.eventId})
      : super(key: key);

  @override
  _VoteScreenState createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> with TickerProviderStateMixin {
  String? _userVote;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _checkUserVote();
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

  Future<void> _checkUserVote() async {
    final voteRef = FirebaseFirestore.instance
        .collection('votes')
        .where('eventId', isEqualTo: widget.eventId)
        .where('userId', isEqualTo: widget.userId);
    final existingVote = await voteRef.get();
    if (existingVote.docs.isNotEmpty) {
      setState(() {
        _userVote = existingVote.docs.first['choice'];
      });
    }
  }

  Future<void> _submitVote(String choice) async {
    try {
      String customVoteId = "${widget.eventId}_${widget.userId}";

      final voteRef =
          FirebaseFirestore.instance.collection('votes').doc(customVoteId);
      final eventHistoryRef = FirebaseFirestore.instance
          .collection('event_history')
          .doc(customVoteId);

      final existingVote = await voteRef.get();
      if (existingVote.exists) {
        await voteRef.update({'choice': choice});
      } else {
        await voteRef.set({
          'eventId': widget.eventId,
          'userId': widget.userId,
          'choice': choice,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      final existingHistory = await eventHistoryRef.get();
      if (existingHistory.exists) {
        await eventHistoryRef.update({
          'action': 'vote',
          'details': {
            'choice': choice,
            'voteId': customVoteId,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await eventHistoryRef.set({
          'eventId': widget.eventId,
          'userId': widget.userId,
          'action': 'vote',
          'details': {
            'choice': choice,
            'voteId': customVoteId,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _userVote = choice;
      });

      // Couleur du SnackBar basée sur le vote
      Color snackBarColor = _getVoteColor(choice);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Votre vote a été enregistré : $choice",
            style: TextStyle(fontFamily: 'CenturyGothic'),
          ),
          backgroundColor: snackBarColor,
        ),
      );
    } catch (e) {
      print("Erreur lors du vote : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur lors du vote, réessayez.",
            style: TextStyle(fontFamily: 'CenturyGothic'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour obtenir la couleur associée à chaque vote
  Color _getVoteColor(String? choice) {
    switch (choice) {
      case "Oui":
        return Color(0xFF5cc29b); // Vert
      case "Non":
        return Color(0xFFF26060); // Rouge
      case "S'abstenir": // Correction de la syntaxe
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
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
                              "Vote pour l'événement",
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 100), // Espace pour descendre un peu
                          // Conteneur pour le titre et les boutons de vote
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
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
                                    children: [
                                      Text(
                                        "Choisissez votre vote",
                                        style: TextStyle(
                                          fontFamily: 'CenturyGothic',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0E6655),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20),
                                      _voteButton("Oui", Color(0xFF5cc29b)),
                                      SizedBox(height: 16),
                                      _voteButton("Non", Color(0xFFF26060)),
                                      SizedBox(height: 16),
                                      _voteButton("S'abstenir", Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Conteneur pour le vote actuel
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
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
                                    children: [
                                      Text(
                                        "Vous avez voté par",
                                        style: TextStyle(
                                          fontFamily: 'CenturyGothic',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0E6655),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        _userVote ?? 'Aucun vote',
                                        style: TextStyle(
                                          fontFamily: 'CenturyGothic',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _getVoteColor(_userVote),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 50), // Espace en bas
                        ],
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

  Widget _voteButton(String text, Color color) {
    bool isSelected = _userVote == text;
    return GestureDetector(
      onTap: () => _submitVote(text),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5, tileMode: ui.TileMode.clamp),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.8) // Plus foncé quand sélectionné
                  : color.withOpacity(0.3), // Clair par défaut
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
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
                  fontSize: 20,
                  color: isSelected ? Colors.white : Color(0xFF0E6655),
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
          top: top +
              (math.sin(widget.controller.value * 2 * math.pi + initialAngle) * 20),
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
