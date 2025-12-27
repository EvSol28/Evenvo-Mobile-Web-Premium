import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb && !Uri.base.host.contains('localhost')) {
      // URL du backend déployé sur Render
      return 'https://evenvo-demo-premium.onrender.com';
    } else {
      // En développement local
      return 'http://localhost:4001';
    }
  }
  
  static String get environment {
    if (kIsWeb && !Uri.base.host.contains('localhost')) {
      return 'production';
    } else {
      return 'development';
    }
  }
  
  // URLs des endpoints
  static String activeVoteForms(String eventId) => '$baseUrl/api/event/$eventId/active_vote_forms';
  static String submitVote(String eventId) => '$baseUrl/api/event/$eventId/submit_vote';
}