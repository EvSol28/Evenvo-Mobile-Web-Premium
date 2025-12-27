import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;

class DynamicVoteScreen extends StatefulWidget {
  final String userId;
  final String eventId;
  final bool canVote;

  const DynamicVoteScreen({
    Key? key,
    required this.userId,
    required this.eventId,
    required this.canVote,
  }) : super(key: key);

  @override
  _DynamicVoteScreenState createState() => _DynamicVoteScreenState();
}

class _DynamicVoteScreenState extends State<DynamicVoteScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _voteForms = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _backgroundController;
  Map<String, Map<String, dynamic>> _formResponses = {};

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _loadVoteForms();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _loadVoteForms() async {
    try {
      // Remplacez par votre URL de serveur
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/event/${widget.eventId}/active_vote_forms'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _voteForms = List<Map<String, dynamic>>.from(data['voteForms']);
            _isLoading = false;
          });
          
          // Initialiser les réponses pour chaque formulaire
          for (var form in _voteForms) {
            _formResponses[form['id']] = {};
          }
        } else {
          setState(() {
            _error = data['message'] ?? 'Erreur lors du chargement';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Erreur de connexion au serveur';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitVote(String formId) async {
    if (!widget.canVote) {
      _showMessage("Vous n'avez pas le droit de voter pour cet événement.", Colors.red);
      return;
    }

    final responses = _formResponses[formId];
    if (responses == null || responses.isEmpty) {
      _showMessage("Veuillez répondre à au moins une question.", Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/event/${widget.eventId}/submit_vote'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'formId': formId,
          'userId': widget.userId,
          'responses': responses,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        _showMessage(data['message'] ?? 'Vote enregistré avec succès', Colors.green);
        // Optionnel: recharger les formulaires ou marquer comme voté
        _loadVoteForms();
      } else {
        _showMessage(data['message'] ?? 'Erreur lors du vote', Colors.red);
      }
    } catch (e) {
      _showMessage('Erreur de connexion: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'CenturyGothic'),
        ),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildFormField(Map<String, dynamic> field, String formId) {
    final fieldId = field['id'];
    final fieldType = field['type'];
    final label = field['label'] ?? '';
    final required = field['required'] ?? false;
    final options = field['options'] as List<dynamic>?;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (required ? ' *' : ''),
            style: TextStyle(
              fontFamily: 'CenturyGothic',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0E6655),
            ),
          ),
          SizedBox(height: 8),
          _buildFieldInput(fieldType, fieldId, formId, options),
        ],
      ),
    );
  }

  Widget _buildFieldInput(String type, String fieldId, String formId, List<dynamic>? options) {
    switch (type) {
      case 'text':
        return TextFormField(
          decoration: InputDecoration(
            hintText: 'Votre réponse',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655), width: 2),
            ),
          ),
          onChanged: (value) {
            _formResponses[formId]![fieldId] = value;
          },
        );

      case 'textarea':
        return TextFormField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Votre réponse détaillée',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655), width: 2),
            ),
          ),
          onChanged: (value) {
            _formResponses[formId]![fieldId] = value;
          },
        );

      case 'radio':
        return Column(
          children: options?.map<Widget>((option) {
            return RadioListTile<String>(
              title: Text(
                option.toString(),
                style: TextStyle(fontFamily: 'CenturyGothic'),
              ),
              value: option.toString(),
              groupValue: _formResponses[formId]?[fieldId],
              onChanged: (value) {
                setState(() {
                  _formResponses[formId]![fieldId] = value;
                });
              },
              activeColor: Color(0xFF0E6655),
            );
          }).toList() ?? [],
        );

      case 'checkbox':
        return Column(
          children: options?.map<Widget>((option) {
            final currentValues = _formResponses[formId]?[fieldId] as List<String>? ?? [];
            return CheckboxListTile(
              title: Text(
                option.toString(),
                style: TextStyle(fontFamily: 'CenturyGothic'),
              ),
              value: currentValues.contains(option.toString()),
              onChanged: (bool? value) {
                setState(() {
                  if (_formResponses[formId]![fieldId] == null) {
                    _formResponses[formId]![fieldId] = <String>[];
                  }
                  final list = _formResponses[formId]![fieldId] as List<String>;
                  if (value == true) {
                    list.add(option.toString());
                  } else {
                    list.remove(option.toString());
                  }
                });
              },
              activeColor: Color(0xFF0E6655),
            );
          }).toList() ?? [],
        );

      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655), width: 2),
            ),
          ),
          hint: Text('Choisir une option'),
          value: _formResponses[formId]?[fieldId],
          items: options?.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(
              value: option.toString(),
              child: Text(option.toString()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _formResponses[formId]![fieldId] = value;
            });
          },
        );

      case 'number':
        return TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Entrez un nombre',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655), width: 2),
            ),
          ),
          onChanged: (value) {
            _formResponses[formId]![fieldId] = int.tryParse(value) ?? value;
          },
        );

      case 'date':
        return TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Sélectionner une date',
            suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF0E6655)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF0E6655), width: 2),
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                _formResponses[formId]![fieldId] = date.toIso8601String().split('T')[0];
              });
            }
          },
          controller: TextEditingController(
            text: _formResponses[formId]?[fieldId]?.toString() ?? '',
          ),
        );

      case 'rating':
        return Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final currentRating = _formResponses[formId]?[fieldId] as int? ?? 0;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _formResponses[formId]![fieldId] = rating;
                });
              },
              child: Icon(
                Icons.star,
                size: 40,
                color: rating <= currentRating ? Colors.amber : Colors.grey[300],
              ),
            );
          }),
        );

      default:
        return Text('Type de champ non supporté: $type');
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
                children: [
                  // Header
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
                              "Formulaires de Vote",
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
                                builder: (context) => Scaffold(
                                  body: Center(child: Text('Déconnecté')),
                                ),
                              ),
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
                  
                  // Content
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0E6655),
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        fontFamily: 'CenturyGothic',
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isLoading = true;
                                          _error = null;
                                        });
                                        _loadVoteForms();
                                      },
                                      child: Text('Réessayer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF0E6655),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _voteForms.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.poll_outlined,
                                          size: 64,
                                          color: Color(0xFF0E6655),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Aucun formulaire de vote disponible",
                                          style: TextStyle(
                                            fontFamily: 'CenturyGothic',
                                            fontSize: 18,
                                            color: Color(0xFF0E6655),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.all(16),
                                    itemCount: _voteForms.length,
                                    itemBuilder: (context, index) {
                                      final form = _voteForms[index];
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 24),
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
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Form title and description
                                                  Text(
                                                    form['name'] ?? 'Formulaire de vote',
                                                    style: TextStyle(
                                                      fontFamily: 'CenturyGothic',
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0E6655),
                                                    ),
                                                  ),
                                                  if (form['description'] != null && form['description'].isNotEmpty) ...[
                                                    SizedBox(height: 8),
                                                    Text(
                                                      form['description'],
                                                      style: TextStyle(
                                                        fontFamily: 'CenturyGothic',
                                                        fontSize: 14,
                                                        color: Color(0xFF6F6F6F),
                                                      ),
                                                    ),
                                                  ],
                                                  SizedBox(height: 20),
                                                  
                                                  // Form fields
                                                  ...((form['fields'] as List<dynamic>?) ?? []).map<Widget>((field) {
                                                    return _buildFormField(field as Map<String, dynamic>, form['id']);
                                                  }).toList(),
                                                  
                                                  SizedBox(height: 20),
                                                  
                                                  // Submit button
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: widget.canVote 
                                                          ? () => _submitVote(form['id'])
                                                          : null,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(0xFF0E6655),
                                                        padding: EdgeInsets.symmetric(vertical: 16),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(30),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        widget.canVote ? 'Soumettre le vote' : 'Vote non autorisé',
                                                        style: TextStyle(
                                                          fontFamily: 'CenturyGothic',
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
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