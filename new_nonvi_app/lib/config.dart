import 'package:flutter/foundation.dart';


const String LOCAL_IP = '';

const String API_BASE_URL = 
  kReleaseMode 
    ? 'https://votre-api-production.com' 
    : 'http://$LOCAL_IP:3000';

class ApiConfig {
  static const String localIP = LOCAL_IP;
  static const int port = 3000;
  
  static String get baseUrl => 'http://$localIP:$port';
  
  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get verifyToken => '$baseUrl/verify-token';
  static String get forgotPassword => '$baseUrl/forgot-password';
  static String get resetPassword => '$baseUrl/reset-password';
  
  static const Duration timeout = Duration(seconds: 30);
  
  static void printConfig() {
    debugPrint('🌐 API CONFIGURATION');
    debugPrint('📍 Base URL: $baseUrl');
    debugPrint('🔌 Port: $port');
    debugPrint('⏱️ Timeout: ${timeout.inSeconds}s');
    debugPrint('🏠 Local IP: $localIP');
    
  }
}

class PrefKeys {
  static const String isFirstLaunch = 'isFirstLaunch';
  static const String userToken = 'userToken';
  static const String isProfileCompleted = 'isProfileCompleted';
  static const String userName = 'userName';
  static const String selectedLanguage = 'selectedLanguage';
  static const String lastPeriodDate = 'lastPeriodDate';
  static const String cycleDuration = 'cycleDuration';
  static const String periodDuration = 'periodDuration';
  static const String profileImagePath = 'profileImagePath';
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String isDarkMode = 'isDarkMode';
}