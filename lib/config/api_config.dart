import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // Utiliser le serveur local pour les tests de développement
    return 'http://localhost:4001';
  }
  
  static String get environment {
    return 'development';
  }
  
  // URLs des endpoints
  static String activeVoteForms(String eventId) => '$baseUrl/api/event/$eventId/active_vote_forms';
  static String submitVote(String eventId) => '$baseUrl/api/event/$eventId/submit_vote';
  static String voteStatus(String eventId, String userId, String formId) => '$baseUrl/api/event/$eventId/vote_status/$userId/$formId';
  static String userResponses(String eventId, String userId, String formId) => '$baseUrl/api/event/$eventId/user_responses/$userId/$formId';
}