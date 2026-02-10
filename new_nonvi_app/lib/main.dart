import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ AJOUTER CETTE LIGNE
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nonvis/screens/login_page.dart';
import 'package:nonvis/screens/home.dart';
import 'package:nonvis/screens/profile_setup_page.dart';
import 'package:nonvis/screens/cycle_manager.dart';
import 'package:nonvis/screens/reset_password_page.dart';
import 'package:nonvis/middleware/auth_middleware.dart';
import 'package:nonvis/config.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('═══════════════════════════════════════');
  debugPrint('🚀 DÉMARRAGE DE L\'APPLICATION NONVI');
  debugPrint('═══════════════════════════════════════');
  
  try {
    debugPrint(' Initialisation du CycleManager...');
    final cycleManager = CycleManager();
    await cycleManager.initialize();
    debugPrint(' CycleManager initialisé avec succès');
  } catch (e) {
    debugPrint(' Erreur initialisation CycleManager: $e');
  }
  
  try {
    debugPrint('💾 Vérification des préférences...');
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    
    if (isFirstLaunch) {
      debugPrint('Premier lancement détecté');
    } else {
      debugPrint('👤 Utilisateur existant');
    }
    
    prefs.setBool('isFirstLaunch', isFirstLaunch);
  } catch (e) {
    debugPrint('Erreur initialisation préférences: $e');
  }
  
  debugPrint('═══════════════════════════════════════');
  
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      debugPrint('🔗 Initialisation des deep links...');
      _appLinks = AppLinks();

      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 Deep link initial détecté: $initialLink');
        Future.delayed(const Duration(seconds: 1), () {
          _handleDeepLink(initialLink);
        });
      } else {
        debugPrint('ℹ️ Aucun deep link initial');
      }

      _deepLinkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            debugPrint('🔗 Deep link reçu: $uri');
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          debugPrint('❌ Erreur deep link stream: $err');
        },
      );
      
      debugPrint('✅ Deep links initialisés');
    } catch (e) {
      debugPrint('❌ Erreur initialisation deep links: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    try {
      
      if (uri.path.contains('reset-password') || uri.host == 'reset-password') {
        final email = uri.queryParameters['email'];
        final token = uri.queryParameters['token'];

        debugPrint('📧 Email: $email');
        debugPrint('🔑 Token: ${token?.substring(0, 10) ?? "null"}...');

        if (email != null && token != null && email.isNotEmpty && token.isNotEmpty) {
          debugPrint(' Paramètres valides - Navigation vers reset password');
        
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ResetPasswordPage(
                email: email,
                token: token,
              ),
            ),
          );

          _showSnackBar(
            ' Redirection vers la réinitialisation du mot de passe',
            Colors.blue,
          );
        } else {
          debugPrint(' Paramètres manquants ou invalides');
          _showSnackBar(
            ' Lien invalide. Paramètres manquants.',
            Colors.red,
          );
        }
      } else {
        debugPrint('Deep link non reconnu: ${uri.path}');
      }
    } catch (e) {
      debugPrint(' Erreur traitement deep link: $e');
      _showSnackBar(
        ' Erreur: Impossible de traiter le lien',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == Colors.red ? Icons.error_outline : Icons.info_outline,
                color: Colors.white,
              ),
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
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NONVI',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
      
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFF4A148C),
        ),
      ),
      home: const AuthSplashScreen(),
    );
  }
}

class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({Key? key}) : super(key: key);

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  final _secureStorage = const FlutterSecureStorage();
  String _statusMessage = 'Démarrage...';

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
      debugPrint('📱 Status: $message');
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      _updateStatus('Vérification du token...');
      
      final token = await _secureStorage.read(key: 'userToken');
      
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Aucun token trouvé');
        _updateStatus('Redirection vers la connexion...');
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
        return;
      }

      debugPrint('✅ Token trouvé: ${token.substring(0, 20)}...');
      _updateStatus('Validation du token...');

      final isValid = await AuthMiddleware.isTokenValid();
      
      if (!isValid) {
        debugPrint('❌ Token invalide ou expiré');
        _updateStatus('Session expirée...');
        
        if (mounted) {
          await AuthMiddleware.logout(
            context,
            message: 'Votre session a expiré. Veuillez vous reconnecter.',
          );
        }
        return;
      }

      debugPrint('✅ Token valide');
      _updateStatus('Chargement du profil...');

      final prefs = await SharedPreferences.getInstance();
      final isProfileCompleted = prefs.getBool(PrefKeys.isProfileCompleted) ?? false;
      final userName = prefs.getString(PrefKeys.userName) ?? 'Utilisateur';

      debugPrint('👤 Utilisateur: $userName');
      debugPrint('📋 Profil complété: $isProfileCompleted');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (isProfileCompleted) {
          debugPrint(' Navigation vers HomePage');
          _updateStatus('Bienvenue $userName !');
          
          await Future.delayed(const Duration(milliseconds: 300));
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          debugPrint(' Profil non complété - Navigation vers ProfileSetupPage');
          _updateStatus('Configuration du profil...');
          
          await Future.delayed(const Duration(milliseconds: 300));
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
          );
        }
      }
      
    } catch (e, stackTrace) {
      debugPrint(' ERREUR LORS DE LA VÉRIFICATION');
      debugPrint('Erreur: $e');
      debugPrint('StackTrace: $stackTrace');
      
      _updateStatus('Erreur de connexion...');
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE91E63), Color(0xFF4A148C)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        size: 70,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Titre animé
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: const Text(
                      'NONVI',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Ton compagnon cycle menstruel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              
              const SizedBox(height: 48),
              
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              
              const SizedBox(height: 24),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessage,
                  key: ValueKey<String>(_statusMessage),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}