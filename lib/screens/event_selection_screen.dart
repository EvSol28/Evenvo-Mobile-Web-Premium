import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Evenvo_Mobile/screens/user_profile_screen.dart';
import 'package:Evenvo_Mobile/screens/authentication_screen.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class EventSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EventSelectionScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _EventSelectionScreenState createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<EventSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;

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
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userData['id'].toString();
    final userEvents = (widget.userData['events'] is List)
        ? List<String>.from(widget.userData['events'] ?? [])
        : [];

    print('User ID: $userId');
    print('User Events: $userEvents');

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
                      padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 48), // Espace pour équilibrer avec l'icône
                          Expanded(
                            child: Center(
                              child: Text(
                                "Événements actifs",
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
                                MaterialPageRoute(builder: (context) => AuthenticationScreen()),
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
                    SizedBox(height: 20),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('events')
                            .where(FieldPath.documentId,
                                whereIn: userEvents.isNotEmpty ? userEvents : ['dummy'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                                child: CircularProgressIndicator(color: Color(0xFF0E6655)));
                          }
                          if (snapshot.hasError) {
                            print('Erreur dans le snapshot: ${snapshot.error}');
                            return Center(
                              child: Text(
                                "Erreur de chargement: ${snapshot.error}",
                                style: TextStyle(
                                  fontFamily: 'CenturyGothic',
                                  fontSize: 14,
                                  color: Color(0xFF0E6655).withOpacity(0.8),
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            print('Aucun événement trouvé dans Firestore ou userEvents vide');
                            return Center(
                              child: Text(
                                "Aucun événement disponible",
                                style: TextStyle(
                                  fontFamily: 'CenturyGothic',
                                  fontSize: 14,
                                  color: Color(0xFF0E6655).withOpacity(0.8),
                                ),
                              ),
                            );
                          }

                          final today = DateTime.now().toUtc();
                          print('Date actuelle (UTC): $today');

                          final filteredEvents = snapshot.data!.docs.where((event) {
                            final eventData = event.data() as Map<String, dynamic>;
                            final startDateStr = eventData['startDate'] as String?;
                            final endDateStr = eventData['endDate'] as String?;

                            print(
                                'Événement ${event.id}: startDate=$startDateStr, endDate=$endDateStr');

                            if (startDateStr == null || endDateStr == null) {
                              print('Dates manquantes pour ${event.id}');
                              return false;
                            }

                            final startDate = DateTime.tryParse(startDateStr)?.toUtc();
                            final endDate = DateTime.tryParse(endDateStr)?.toUtc();

                            if (startDate == null || endDate == null) {
                              print('Erreur de parsing des dates pour ${event.id}');
                              return false;
                            }

                            final isActive = (startDate.isBefore(today) ||
                                    startDate.isAtSameMomentAs(today)) &&
                                (endDate.isAfter(today) || endDate.isAtSameMomentAs(today));

                            print(
                                'Événement ${event.id} - Actif: $isActive (start: $startDate, end: $endDate)');
                            return isActive;
                          }).toList();

                          if (filteredEvents.isEmpty) {
                            print('Aucun événement actif après filtrage');
                            return Center(
                              child: Text(
                                "Aucun événement actif actuellement",
                                style: TextStyle(
                                  fontFamily: 'CenturyGothic',
                                  fontSize: 14,
                                  color: Color(0xFF0E6655).withOpacity(0.8),
                                ),
                              ),
                            );
                          }

                          print('Événements filtrés: ${filteredEvents.length}');
                          return ListView.builder(
                            itemCount: filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = filteredEvents[index];
                              final eventData = event.data() as Map<String, dynamic>?;

                              if (eventData == null) {
                                print("Erreur: Données nulles pour l'événement ${event.id}");
                                return SizedBox.shrink();
                              }

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      padding: EdgeInsets.all(20),
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
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          eventData['name'] ?? 'Événement sans nom',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF0E6655),
                                            fontFamily: 'CenturyGothic',
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Du ${eventData['startDate']} au ${eventData['endDate']}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF0E6655).withOpacity(0.8),
                                            fontFamily: 'CenturyGothic',
                                          ),
                                        ),
                                        trailing:
                                            Icon(Icons.arrow_forward_ios, color: Color(0xFF0E6655)),
                                        onTap: () {
                                          _navigateBasedOnRole(
                                              context, event.id, eventData, userId);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateBasedOnRole(
      BuildContext context, String eventId, Map<String, dynamic> eventData, String userId) {
    final role = widget.userData['role'];
    if (role == 'Membre' || role == 'Organisateur' || role == 'Administrateur') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userData: widget.userData..addAll({'eventId': eventId, 'eventData': eventData}),
          ),
        ),
      );
      _updatePresenceInFirestore(userId, eventId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Rôle non pris en charge",
            style: TextStyle(fontFamily: 'CenturyGothic'),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
        final eventHistoryRef =
            FirebaseFirestore.instance.collection('event_history').doc('${eventId}_$userId');

        await eventRef.update({'presence.$userId': true});
        await eventHistoryRef.set({
          'eventId': eventId,
          'userId': userId,
          'userName': '${userData['name']} ${userData['surname']}',
          'role': userData['role'] ?? 'Non défini',
          'email': userData['email'] ?? 'Non disponible',
          'presence': true,
          'addedDate': FieldValue.serverTimestamp(),
          'eventEndDate': (await eventRef.get()).data()?['endDate'],
        }, SetOptions(merge: true));
        print('Présence mise à jour dans events et event_history');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la présence : $e');
    }
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