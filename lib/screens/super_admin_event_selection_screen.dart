import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Evenvo_Mobile/screens/super_admin_scan_screen.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class SuperAdminEventSelectionScreen extends StatefulWidget {
  @override
  _SuperAdminEventSelectionScreenState createState() => _SuperAdminEventSelectionScreenState();
}

class _SuperAdminEventSelectionScreenState extends State<SuperAdminEventSelectionScreen>
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
                  crossAxisAlignment: CrossAxisAlignment.center, // Centrer horizontalement
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 48), // Espace pour équilibrer avec l'icône à droite
                          Expanded(
                            child: Center(
                              child: Text(
                                "Événement actifs",
                                style: TextStyle(
                                  fontFamily: 'CenturyGothic',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6F6F6F),
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center, // Centrer le texte
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
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('events').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: Color(0xFF0E6655)));
                          }
                          if (snapshot.hasError) {
                            print("Erreur dans StreamBuilder: ${snapshot.error}");
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
                            print("Aucune donnée trouvée dans la collection 'events'");
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
                          print("Date actuelle (UTC): $today");

                          final activeEvents = snapshot.data!.docs.where((event) {
                            final eventData = event.data();
                            print("Données brutes de l'événement ${event.id}: $eventData");

                            if (eventData is! Map<String, dynamic>) {
                              print("Erreur: Les données de l'événement ne sont pas une Map: $eventData");
                              return false;
                            }

                            final startDateStr = eventData['startDate'] as String?;
                            final endDateStr = eventData['endDate'] as String?;

                            if (startDateStr == null || endDateStr == null) {
                              print("Erreur: startDate ou endDate manquant pour l'événement ${event.id}");
                              return false;
                            }

                            final startDate = DateTime.tryParse(startDateStr)?.toUtc();
                            final endDate = DateTime.tryParse(endDateStr)?.toUtc();

                            if (startDate == null || endDate == null) {
                              print("Erreur: Impossible de parser les dates pour l'événement ${event.id}");
                              return false;
                            }

                            print("Événement ${event.id} - Début: $startDate, Fin: $endDate");
                            return (startDate.isBefore(today) || startDate.isAtSameMomentAs(today)) &&
                                endDate.isAfter(today);
                          }).toList();

                          if (activeEvents.isEmpty) {
                            print("Aucun événement actif trouvé");
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

                          return ListView.builder(
                            itemCount: activeEvents.length,
                            itemBuilder: (context, index) {
                              final event = activeEvents[index];
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
                                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5, tileMode: ui.TileMode.clamp),
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
                                        trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF0E6655)),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SuperAdminScanScreen(
                                                eventId: event.id,
                                                eventData: eventData,
                                              ),
                                            ),
                                          );
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
          top: top + (math.sin(widget.controller.value * 2 * math.pi + initialAngle) * 20).toDouble(),
          left: 20 + (math.cos(widget.controller.value * 2 * math.pi + initialAngle) * 20).toDouble(),
          child: Transform.rotate(
            angle: widget.controller.value * 2 * math.pi + initialAngle,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size / (4 + (math.sin(widget.controller.value * math.pi) * 2).toDouble())),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: shapes);
  }
}