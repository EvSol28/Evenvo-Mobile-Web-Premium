import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // Toujours utiliser l'URL de production pour éviter les problèmes de connexion
    return 'https://evenvo-demo-premium.onrender.com';
  }
  
  static String get environment {
    return 'production';
  }
  
  // URLs des endpoints
  static String activeVoteForms(String eventId) => '$baseUrl/api/event/$eventId/active_vote_forms';
  static String submitVote(String eventId) => '$baseUrl/api/event/$eventId/submit_vote';
  static String voteStatus(String eventId, String userId, String formId) => '$baseUrl/api/event/$eventId/vote_status/$userId/$formId';
  static String userResponses(String eventId, String userId, String formId) => '$baseUrl/api/event/$eventId/user_responses/$userId/$formId';
}