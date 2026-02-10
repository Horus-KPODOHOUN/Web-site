import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nonvis/config.dart';
import 'package:nonvis/screens/login_page.dart';

class AuthMiddleware {
  static const _secureStorage = FlutterSecureStorage();

  static Future<bool> isTokenValid() async {
    try {
      debugPrint('🔍 Vérification de la validité du token...');
      
      final token = await _secureStorage.read(key: 'userToken');
      
      if (token == null || token.isEmpty) {
        debugPrint('❌ Token absent');
        return false;
      }

      debugPrint('📡 Envoi de la requête de vérification à: $API_BASE_URL/verify-token');
      
      final response = await http.get(
        Uri.parse('$API_BASE_URL/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Timeout de la vérification du token');
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      debugPrint('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Token valide');
        debugPrint('👤 User ID: ${data['user']?['id']}');
        
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            PrefKeys.userName,
            data['user']['name'] ?? 'Utilisateur',
          );
          if (data['user']['email'] != null) {
            await prefs.setString('userEmail', data['user']['email']);
          }
          if (data['user']['phone'] != null) {
            await prefs.setString('userPhone', data['user']['phone']);
          }
        }
        
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('❌ Token invalide ou expiré (${response.statusCode})');
        return false;
      } else {
        debugPrint('⚠️ Erreur inattendue: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception lors de la vérification du token');
      debugPrint('Erreur: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: 'userToken');
      if (token != null && token.isNotEmpty) {
        debugPrint('✅ Token récupéré: ${token.substring(0, 20)}...');
        return token;
      }
      debugPrint('⚠️ Aucun token disponible');
      return null;
    } catch (e) {
      debugPrint(' Erreur récupération token: $e');
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: 'userToken', value: token);
      debugPrint('✅ Token sauvegardé: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('Erreur sauvegarde token: $e');
    }
  }

  static Future<void> logout(BuildContext context, {String? message}) async {
    try {
      debugPrint('🚪 DÉCONNEXION EN COURS');
      
      await _secureStorage.delete(key: 'userToken');
      debugPrint('✅ Token supprimé');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userEmail');
      await prefs.remove('userPhone');
      await prefs.setBool(PrefKeys.isProfileCompleted, false);
      debugPrint('✅ Préférences nettoyées');
      
      if (message != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
      
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
    }
  }

  static Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorage.read(key: 'userToken');
      final hasToken = token != null && token.isNotEmpty;
      
      if (hasToken) {
        debugPrint(' Utilisateur authentifié (token présent)');
      } else {
        debugPrint(' Utilisateur non authentifié (pas de token)');
      }
      
      return hasToken;
    } catch (e) {
      debugPrint(' Erreur vérification authentification: $e');
      return false;
    }
  }

  static Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        debugPrint(' Pas de token pour la requête authentifiée');
        return http.Response('{"error": "No token"}', 401);
      }

      final defaultHeaders = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      final uri = Uri.parse('$API_BASE_URL$endpoint');
      debugPrint(' Requête $method vers: $uri');

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: defaultHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: defaultHeaders);
          break;
        default:
          throw Exception('Méthode HTTP non supportée: $method');
      }

      debugPrint(' Réponse: ${response.statusCode}');

      return response;
    } catch (e) {
      debugPrint(' Erreur requête authentifiée: $e');
      return http.Response('{"error": "$e"}', 500);
    }
  }

  static Future<void> handleAuthError(
    BuildContext context,
    int statusCode, {
    String? customMessage,
  }) async {
    String message;
    
    switch (statusCode) {
      case 401:
        message = customMessage ?? 'Session expirée. Veuillez vous reconnecter.';
        await logout(context, message: message);
        break;
      case 403:
        message = customMessage ?? 'Accès refusé.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
        break;
      default:
        message = customMessage ?? 'Erreur d\'authentification.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }
}