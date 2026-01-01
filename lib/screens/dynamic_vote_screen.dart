import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

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

// FORCE REBUILD - Version 2025-12-30-15:47
class _DynamicVoteScreenState extends State<DynamicVoteScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _voteForms = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _backgroundController;
  Map<String, bool> _voteStatus = {}; // Track which forms have been voted on
  String? _selectedFormId; // Track which form is currently being voted on
  Map<String, Map<String, dynamic>> _formResponses = {}; // Store form responses

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
      print('🔍 Chargement des formulaires pour eventId: ${widget.eventId}');
      print('🌐 Environnement: ${ApiConfig.environment}');
      print('🌐 URL du serveur: ${ApiConfig.baseUrl}');
      print('🌐 URL complète: ${ApiConfig.activeVoteForms(widget.eventId)}');
      
      // Essayer d'abord avec l'ID tel quel
      var response = await http.get(
        Uri.parse(ApiConfig.activeVoteForms(widget.eventId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(seconds: 30), // Augmenter le timeout
        onTimeout: () {
          print('❌ Timeout lors de la requête');
          throw Exception('Timeout de la requête');
        },
      );

      print('📡 Réponse serveur (${widget.eventId}): ${response.statusCode}');
      
      // Si pas de résultats, essayer avec la première lettre en majuscule
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 Données reçues: $data');
        if (data['success'] && data['voteForms'].isEmpty) {
          final capitalizedEventId = widget.eventId.replaceFirst(widget.eventId[0], widget.eventId[0].toUpperCase());
          print('🔄 Tentative avec ID capitalisé: $capitalizedEventId');
          
          response = await http.get(
            Uri.parse(ApiConfig.activeVoteForms(capitalizedEventId)),
            headers: {'Content-Type': 'application/json'},
          ).timeout(
            Duration(seconds: 30),
            onTimeout: () {
              print('❌ Timeout lors de la requête (capitalisé)');
              throw Exception('Timeout de la requête');
            },
          );
          print('📡 Réponse serveur ($capitalizedEventId): ${response.statusCode}');
        }
      }

      print('📄 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _voteForms = List<Map<String, dynamic>>.from(data['voteForms']);
            _isLoading = false;
          });
          
          print('✅ Formulaires chargés: ${_voteForms.length}');
          // Log each form's fields for debugging
          for (var form in _voteForms) {
            print('📋 Formulaire: ${form['name']}');
            if (form['fields'] != null) {
              for (var field in form['fields']) {
                print('  🔸 Champ: ${field['type']} - ${field['label']} - allowComments: ${field['allowComments']}');
              }
            }
          }
          
          // Check vote status for each form
          await _checkVoteStatus();
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

  Future<void> _checkVoteStatus() async {
    try {
      // Check if user has already voted on each form by calling the backend
      for (var form in _voteForms) {
        final formId = form['id'];
        
        // Call backend to check if user has voted on this form
        final response = await http.get(
          Uri.parse(ApiConfig.voteStatus(widget.eventId, widget.userId, formId)),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _voteStatus[formId] = data['hasVoted'] ?? false;
        } else {
          // If endpoint doesn't exist yet, default to false
          _voteStatus[formId] = false;
        }
      }
      setState(() {});
    } catch (e) {
      print('Error checking vote status: $e');
      // Default all to false if there's an error
      for (var form in _voteForms) {
        _voteStatus[form['id']] = false;
      }
    }
  }

  void _selectForm(String formId) {
    setState(() {
      _selectedFormId = formId;
      // Initialize form responses for this form if not already done
      if (!_formResponses.containsKey(formId)) {
        _formResponses[formId] = {};
      }
    });
  }

  void _goBackToFormList() {
    setState(() {
      _selectedFormId = null;
    });
  }

  Future<void> _submitVote(String formId, Map<String, dynamic> formResponses) async {
    if (!widget.canVote) {
      _showMessage("Vous n'avez pas le droit de voter pour cet événement.", Colors.red);
      return;
    }

    if (formResponses.isEmpty) {
      _showMessage("Veuillez répondre à au moins une question.", Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.submitVote(widget.eventId)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'formId': formId,
          'userId': widget.userId,
          'responses': formResponses,
          'allowUpdate': true, // Permettre la mise à jour
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        final isUpdate = data['isUpdate'] ?? false;
        _showMessage(
          data['message'] ?? (isUpdate ? 'Vote mis à jour avec succès' : 'Vote enregistré avec succès'), 
          Colors.green
        );
        
        // Mark form as voted and go back to form list
        setState(() {
          _voteStatus[formId] = true;
          _selectedFormId = null;
        });
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
          _buildFieldInput(fieldType, fieldId, formId, options, field),
        ],
      ),
    );
  }

  Widget _buildFieldInput(String type, String fieldId, String formId, List<dynamic>? options, Map<String, dynamic>? field) {
    // VERSION 2025-12-30-15:47 - NOUVELLE VERSION CHARGÉE
    print('🚀 NOUVELLE VERSION CHARGÉE - 2025-12-30-15:47');
    print('🔍 Type de champ reçu: $type');
    print('🔍 Options: $options');
    print('🔍 Field data: $field');
    
    // Normaliser le type en minuscules pour éviter les problèmes de casse
    final normalizedType = type.toLowerCase().trim();
    print('🔍 Type normalisé: $normalizedType');
    
    // FORCE RANKING SUPPORT - Version temporaire pour debug
    if (normalizedType == 'ranking') {
      print('🎯 RANKING DÉTECTÉ - Création du widget');
      // Créer une liste ordonnée des options pour le classement
      final List<String> rankingOptions = List<String>.from(options ?? []);
      final Map<String, int> currentRanking = Map<String, int>.from(
        _formResponses[formId]?[fieldId] as Map<String, dynamic>? ?? {}
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description du champ si disponible
          if (field != null && field['description'] != null && field['description'].isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF0E6655).withOpacity(0.2)),
              ),
              child: Text(
                field['description'],
                style: TextStyle(
                  fontFamily: 'CenturyGothic',
                  fontSize: 14,
                  color: Color(0xFF0E6655),
                  height: 1.4,
                ),
              ),
            ),
          ],
          // Instructions
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF0E6655).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF0E6655), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Classez les options par ordre de préférence (1 = préféré, ${rankingOptions.length} = moins préféré)',
                    style: TextStyle(
                      fontFamily: 'CenturyGothic',
                      fontSize: 12,
                      color: Color(0xFF0E6655),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Options de classement
          ...rankingOptions.map<Widget>((option) {
            final currentRank = currentRanking[option];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentRank != null 
                    ? Color(0xFF0E6655).withOpacity(0.15) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentRank != null ? Color(0xFF0E6655) : Colors.grey[300]!,
                  width: currentRank != null ? 2 : 1,
                ),
                // Effet glass pour les éléments sélectionnés
                boxShadow: currentRank != null ? [
                  BoxShadow(
                    color: Color(0xFF0E6655).withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'CenturyGothic',
                        fontSize: 16,
                        fontWeight: currentRank != null ? FontWeight.w600 : FontWeight.normal,
                        color: currentRank != null ? Color(0xFF0E6655) : Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Dropdown pour sélectionner le rang
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentRank != null 
                          ? Color(0xFF0E6655).withOpacity(0.15) 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      // Effet glass pour le dropdown sélectionné
                      boxShadow: currentRank != null ? [
                        BoxShadow(
                          color: Color(0xFF0E6655).withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ] : null,
                    ),
                    child: DropdownButton<int>(
                      value: currentRank,
                      hint: Text(
                        'Rang',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'CenturyGothic',
                        ),
                      ),
                      underline: SizedBox(),
                      dropdownColor: Colors.white,
                      items: List.generate(rankingOptions.length, (index) {
                        final rank = index + 1;
                        final isUsed = currentRanking.values.contains(rank) && currentRanking[option] != rank;
                        return DropdownMenuItem<int>(
                          value: rank,
                          enabled: !isUsed,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: isUsed ? Colors.grey[400] : Colors.black87,
                                fontFamily: 'CenturyGothic',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }),
                      onChanged: (int? newRank) {
                        if (newRank != null) {
                          setState(() {
                            if (!_formResponses.containsKey(formId)) {
                              _formResponses[formId] = {};
                            }
                            if (_formResponses[formId]![fieldId] == null) {
                              _formResponses[formId]![fieldId] = <String, int>{};
                            }
                            
                            final ranking = _formResponses[formId]![fieldId] as Map<String, int>;
                            
                            // Supprimer l'ancien rang s'il existe
                            if (ranking[option] != null) {
                              ranking.remove(option);
                            }
                            
                            // Supprimer le rang s'il est utilisé par une autre option
                            ranking.removeWhere((key, value) => value == newRank);
                            
                            // Assigner le nouveau rang
                            ranking[option] = newRank;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: currentRank != null ? Color(0xFF0E6655) : Colors.grey[600],
                      ),
                      style: TextStyle(
                        color: currentRank != null ? Color(0xFF0E6655) : Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'CenturyGothic',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    }
    
    switch (normalizedType) {
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
            if (!_formResponses.containsKey(formId)) {
              _formResponses[formId] = {};
            }
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
            if (!_formResponses.containsKey(formId)) {
              _formResponses[formId] = {};
            }
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
                  if (!_formResponses.containsKey(formId)) {
                    _formResponses[formId] = {};
                  }
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
                  if (!_formResponses.containsKey(formId)) {
                    _formResponses[formId] = {};
                  }
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
              if (!_formResponses.containsKey(formId)) {
                _formResponses[formId] = {};
              }
              _formResponses[formId]![fieldId] = value;
            });
          },
        );

      case 'ranking':
        // Créer une liste ordonnée des options pour le classement
        final List<String> rankingOptions = List<String>.from(options ?? []);
        final Map<String, int> currentRanking = Map<String, int>.from(
          _formResponses[formId]?[fieldId] as Map<String, dynamic>? ?? {}
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description du champ si disponible
            if (field != null && field['description'] != null && field['description'].isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF0E6655).withOpacity(0.2)),
                ),
                child: Text(
                  field['description'],
                  style: TextStyle(
                    fontFamily: 'CenturyGothic',
                    fontSize: 14,
                    color: Color(0xFF0E6655),
                    height: 1.4,
                  ),
                ),
              ),
            ],
            // Instructions
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF0E6655).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0E6655), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Classez les options par ordre de préférence (1 = préféré, ${rankingOptions.length} = moins préféré)',
                      style: TextStyle(
                        fontFamily: 'CenturyGothic',
                        fontSize: 12,
                        color: Color(0xFF0E6655),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Options de classement
            ...rankingOptions.map<Widget>((option) {
              final currentRank = currentRanking[option];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentRank != null ? Color(0xFF0E6655).withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentRank != null ? Color(0xFF0E6655) : Colors.grey[300]!,
                    width: currentRank != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontFamily: 'CenturyGothic',
                          fontSize: 16,
                          fontWeight: currentRank != null ? FontWeight.w600 : FontWeight.normal,
                          color: currentRank != null ? Color(0xFF0E6655) : Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Dropdown pour sélectionner le rang
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentRank != null ? Color(0xFF0E6655) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButton<int>(
                        value: currentRank,
                        hint: Text(
                          'Rang',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'CenturyGothic',
                          ),
                        ),
                        underline: SizedBox(),
                        dropdownColor: Colors.white,
                        items: List.generate(rankingOptions.length, (index) {
                          final rank = index + 1;
                          final isUsed = currentRanking.values.contains(rank) && currentRanking[option] != rank;
                          return DropdownMenuItem<int>(
                            value: rank,
                            enabled: !isUsed,
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: isUsed ? Colors.grey : Color(0xFF0E6655),
                                fontFamily: 'CenturyGothic',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                        onChanged: (int? newRank) {
                          if (newRank != null) {
                            setState(() {
                              if (!_formResponses.containsKey(formId)) {
                                _formResponses[formId] = {};
                              }
                              if (_formResponses[formId]![fieldId] == null) {
                                _formResponses[formId]![fieldId] = <String, int>{};
                              }
                              
                              final ranking = _formResponses[formId]![fieldId] as Map<String, int>;
                              
                              // Supprimer l'ancien rang s'il existe
                              if (ranking[option] != null) {
                                ranking.remove(option);
                              }
                              
                              // Supprimer le rang s'il est utilisé par une autre option
                              ranking.removeWhere((key, value) => value == newRank);
                              
                              // Assigner le nouveau rang
                              ranking[option] = newRank;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: currentRank != null ? Colors.white : Colors.grey[600],
                        ),
                        style: TextStyle(
                          color: currentRank != null ? Colors.white : Color(0xFF0E6655),
                          fontSize: 14,
                          fontFamily: 'CenturyGothic',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
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
                if (!_formResponses.containsKey(formId)) {
                  _formResponses[formId] = {};
                }
                _formResponses[formId]![fieldId] = date.toIso8601String().split('T')[0];
              });
            }
          },
          controller: TextEditingController(
            text: _formResponses[formId]?[fieldId]?.toString() ?? '',
          ),
        );

      case 'rating':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                final rating = index + 1;
                final currentRating = _formResponses[formId]?[fieldId] as int? ?? 0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (!_formResponses.containsKey(formId)) {
                        _formResponses[formId] = {};
                      }
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
            ),
            // Add comment field if allowComments is true
            if (field != null && field['allowComments'] == true) ...[
              SizedBox(height: 16),
              Text(
                'Commentaire (facultatif)',
                style: TextStyle(
                  fontFamily: 'CenturyGothic',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0E6655),
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF0E6655).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF0E6655).withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Laissez un commentaire sur votre évaluation...',
                    hintStyle: TextStyle(
                      fontFamily: 'CenturyGothic',
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: TextStyle(
                    fontFamily: 'CenturyGothic',
                    fontSize: 14,
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (!_formResponses.containsKey(formId)) {
                        _formResponses[formId] = {};
                      }
                      _formResponses[formId]!['${fieldId}_comment'] = value;
                    });
                  },
                ),
              ),
            ],
          ],
        );

      case 'syndical':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description field
            if (field != null && field['description'] != null && field['description'].isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF0E6655).withOpacity(0.2)),
                ),
                child: Text(
                  field['description'],
                  style: TextStyle(
                    fontFamily: 'CenturyGothic',
                    fontSize: 14,
                    color: Color(0xFF0E6655),
                    height: 1.4,
                  ),
                ),
              ),
            ],
            // Vote options as buttons
            Column(
              children: ['Oui', 'Non', 'S\'abstenir'].map<Widget>((option) {
                final isSelected = _formResponses[formId]?[fieldId] == option;
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (!_formResponses.containsKey(formId)) {
                          _formResponses[formId] = {};
                        }
                        _formResponses[formId]![fieldId] = option;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
                          ? Color(0xFF0E6655) 
                          : Colors.white,
                      foregroundColor: isSelected 
                          ? Colors.white 
                          : Color(0xFF0E6655),
                      side: BorderSide(
                        color: Color(0xFF0E6655),
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isSelected ? 4 : 1,
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'CenturyGothic',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

      default:
        return Text('Type de champ non supporté: $normalizedType (original: $type)');
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
                          onPressed: () {
                            if (_selectedFormId != null) {
                              _goBackToFormList();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _selectedFormId != null ? "Vote" : "Voter",
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
                                : _selectedFormId == null
                                    ? _buildFormSelectionList()
                                    : _buildFormVotingInterface(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSelectionList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _voteForms.length,
      itemBuilder: (context, index) {
        final form = _voteForms[index];
        final formId = form['id'];
        final hasVoted = _voteStatus[formId] ?? false;
        
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: widget.canVote ? () => _selectForm(formId) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: hasVoted 
                        ? Colors.grey.withOpacity(0.3) // Gray glass effect for voted forms
                        : Color(0xFFd9f9ef).withOpacity(0.3), // Green glass effect for unvoted forms
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasVoted 
                          ? Colors.grey.withOpacity(0.5)
                          : Color(0xFFd9f9ef).withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: hasVoted 
                            ? Colors.grey.withOpacity(0.1)
                            : Color(0xFFd9f9ef).withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              form['name'] ?? 'Formulaire de vote',
                              style: TextStyle(
                                fontFamily: 'CenturyGothic',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hasVoted ? Colors.grey[600] : Color(0xFF0E6655),
                              ),
                            ),
                            if (form['description'] != null && form['description'].isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                form['description'],
                                style: TextStyle(
                                  fontFamily: 'CenturyGothic',
                                  fontSize: 14,
                                  color: hasVoted ? Colors.grey[500] : Color(0xFF6F6F6F),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      // Status indicator - like in the suivi_vote table
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasVoted ? Color(0xFF0E6655) : Colors.grey[400],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          hasVoted ? 'Voté' : 'Non voté',
                          style: TextStyle(
                            fontFamily: 'CenturyGothic',
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!hasVoted && widget.canVote) ...[
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF0E6655),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormVotingInterface() {
    final form = _voteForms.firstWhere((f) => f['id'] == _selectedFormId);
    final bool hasVoted = _voteStatus[_selectedFormId] ?? false;
    
    // Initialize form responses for this form if not already done
    if (!_formResponses.containsKey(_selectedFormId!)) {
      _formResponses[_selectedFormId!] = {};
    }
    
    return FutureBuilder<Map<String, dynamic>>(
      future: hasVoted ? _loadExistingResponses(_selectedFormId!) : Future.value({}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF0E6655)));
        }
        
        // Initialize form responses with existing data if available
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          _formResponses[_selectedFormId!]!.addAll(snapshot.data!);
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: hasVoted 
                      ? Colors.grey.withOpacity(0.2) 
                      : Color(0xFFd9f9ef).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasVoted 
                        ? Colors.grey.withOpacity(0.5)
                        : Color(0xFFd9f9ef).withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasVoted 
                          ? Colors.grey.withOpacity(0.1)
                          : Color(0xFFd9f9ef).withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form title and description
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            form['name'] ?? 'Formulaire de vote',
                            style: TextStyle(
                              fontFamily: 'CenturyGothic',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: hasVoted ? Colors.grey[600] : Color(0xFF0E6655),
                            ),
                          ),
                        ),
                        if (hasVoted)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF0E6655),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Voté',
                              style: TextStyle(
                                fontFamily: 'CenturyGothic',
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (form['description'] != null && form['description'].isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        form['description'],
                        style: TextStyle(
                          fontFamily: 'CenturyGothic',
                          fontSize: 14,
                          color: hasVoted ? Colors.grey[500] : Color(0xFF6F6F6F),
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
                            ? () => _submitVote(form['id'], _formResponses[form['id']] ?? {})
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasVoted 
                              ? Colors.orange.withOpacity(0.15) 
                              : Color(0xFF0E6655).withOpacity(0.15),
                          foregroundColor: hasVoted ? Colors.orange : Color(0xFF0E6655),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: hasVoted ? Colors.orange : Color(0xFF0E6655),
                              width: 2,
                            ),
                          ),
                          // Effet glass
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ).copyWith(
                          overlayColor: MaterialStateProperty.all(
                            (hasVoted ? Colors.orange : Color(0xFF0E6655)).withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          widget.canVote 
                              ? (hasVoted ? 'Modifier le vote' : 'Soumettre le vote')
                              : 'Vote non autorisé',
                          style: TextStyle(
                            fontFamily: 'CenturyGothic',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasVoted ? Colors.orange : Color(0xFF0E6655),
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
    );
  }

  Future<Map<String, dynamic>> _loadExistingResponses(String formId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userResponses(widget.eventId, widget.userId, formId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['hasVoted']) {
          return Map<String, dynamic>.from(data['responses']);
        }
      }
    } catch (e) {
      print('Error loading existing responses: $e');
    }
    return {};
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