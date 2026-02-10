import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nonvis/config.dart';
import 'package:nonvis/screens/forgot_password_page.dart';
import 'package:nonvis/screens/home.dart';
import 'package:nonvis/screens/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _usePhone = true;
  bool _passwordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _biometricAvailable = false;

  String _countryCode = '+229';
  String? _contactError;
  String? _passwordError;
  String? _loginError;

  int _loginAttempts = 0;
  final int _maxAttempts = 5;
  DateTime? _lockoutTime;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _checkBiometricAvailability();

    _phoneController.addListener(_validateContact);
    _emailController.addListener(_validateContact);
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _biometricAvailable = true;
    });
  }

  void _validateContact() {
    setState(() {
      if (_usePhone) {
        final phone = _phoneController.text;
        if (phone.isEmpty) {
          _contactError = null;
        } else if (phone.length < 8) {
          _contactError = 'Numéro invalide';
        } else {
          _contactError = null;
        }
      } else {
        final email = _emailController.text;
        if (email.isEmpty) {
          _contactError = null;
        } else if (!_isValidEmail(email)) {
          _contactError = 'Email invalide';
        } else {
          _contactError = null;
        }
      }
      _loginError = null;
    });
  }

  void _validatePassword() {
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = null;
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'Mot de passe trop court';
      } else {
        _passwordError = null;
      }
      _loginError = null;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _canLogin() {
    final contactValid = _usePhone
        ? _phoneController.text.length >= 8
        : _isValidEmail(_emailController.text);

    return contactValid &&
        _passwordController.text.length >= 6 &&
        _contactError == null &&
        _passwordError == null &&
        _loginAttempts < _maxAttempts;
  }

  Future<void> _login() async {
    if (!_canLogin()) {
      _shakeController.forward(from: 0);
      return;
    }

    if (_lockoutTime != null && DateTime.now().isBefore(_lockoutTime!)) {
      final remaining = _lockoutTime!.difference(DateTime.now()).inMinutes + 1;
      setState(() {
        _loginError = 'Trop de tentatives. Réessaie dans $remaining minutes';
      });
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      final headers = {'Content-Type': 'application/json'};
      final body = _usePhone
          ? {
              'contact': '$_countryCode${_phoneController.text}',
              'password': _passwordController.text
            }
          : {
              'contact': _emailController.text,
              'password': _passwordController.text
            };

      debugPrint('📡 Envoi requête login vers: $API_BASE_URL/login');
      debugPrint('📋 Body: ${jsonEncode(body)}');

      final response = await http
          .post(
        Uri.parse('$API_BASE_URL/login'),
        headers: headers,
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Délai d\'attente dépassé');
        },
      );

      debugPrint('🔥 Réponse serveur: ${response.statusCode}');
      debugPrint('📋 Body: ${response.body}');

      setState(() => _isLoading = false);

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : {};

      if (response.statusCode == 200) {
        final token = data['token'] as String?;
        debugPrint('🔑 Token reçu: ${token?.substring(0, 20)}...');

        if (token != null && token.isNotEmpty) {
          await _secureStorage.write(key: 'userToken', value: token);

          final savedToken = await _secureStorage.read(key: 'userToken');
          debugPrint(
              '🔐 Token sauvegardé confirmé: ${savedToken?.substring(0, 20)}...');
        } else {
          debugPrint('⚠️ Aucun token reçu du serveur !');
          setState(() => _loginError = 'Erreur serveur: Token manquant');
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        if (data['user'] != null) {
          final user = data['user'] as Map<String, dynamic>;
          await prefs.setString(
              PrefKeys.userName, user['name'] ?? 'Utilisateur');
          await prefs.setString('userEmail', user['email'] ?? '');
          await prefs.setString('userPhone', user['phone'] ?? '');
          await prefs.setBool(
              PrefKeys.isProfileCompleted, user['profileCompleted'] == true);

          debugPrint('👤 Utilisateur: ${user['name']}');
          debugPrint('✅ Profil complété: ${user['profileCompleted']}');
        } else {
          await prefs.setString(
              PrefKeys.userName, data['name'] ?? 'Utilisateur');
          await prefs.setBool(
              PrefKeys.isProfileCompleted, data['profileCompleted'] == true);
        }

        if (_rememberMe) {
          await prefs.setBool('rememberMe', true);
          debugPrint('💾 Remember me activé');
        } else {
          await prefs.setBool('rememberMe', false);
        }

        _onLoginSuccess();
      } else {
        final msg =
            data['error'] ?? data['message'] ?? 'Identifiants incorrects';
        setState(() => _loginError = msg);
        _onLoginError();
      }
    } catch (e) {
      debugPrint('❌ Erreur login: $e');
      setState(() {
        _isLoading = false;
        _loginError = 'Impossible de se connecter : $e';
      });
      _shakeController.forward(from: 0);
    }
  }

  void _onLoginSuccess() async {
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    final String userName = prefs.getString('userName') ?? 'Utilisateur';

    debugPrint('✅ Connexion réussie pour: $userName');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Bienvenue $userName !',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  void _onLoginError() {
    setState(() {
      _loginAttempts++;

      if (_loginAttempts >= _maxAttempts) {
        _lockoutTime = DateTime.now().add(const Duration(minutes: 15));
        _loginError = 'Trop de tentatives. Réessaie dans 15 minutes';
      } else {
        _loginError = 'Identifiants incorrects';
      }
    });

    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  Future<void> _loginWithBiometric() async {
    debugPrint('Connexion par biométrie...');

    await Future.delayed(const Duration(seconds: 1));

    _onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFF4A148C)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bon retour !',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A148C),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Connecte-toi à ton compte',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => debugPrint('Audio: Bon retour'),
                            icon: const Icon(Icons.volume_up,
                                color: Color(0xFFE91E63)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildContactToggle(),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              _shakeAnimation.value *
                                  (_shakeController.status ==
                                          AnimationStatus.forward
                                      ? 1
                                      : -1),
                              0,
                            ),
                            child: child,
                          );
                        },
                        child: Column(
                          children: [
                            if (_usePhone)
                              _buildPhoneField()
                            else
                              _buildTextField(
                                controller: _emailController,
                                label: 'Adresse email',
                                icon: Icons.email_outlined,
                                error: _contactError,
                                keyboardType: TextInputType.emailAddress,
                                hint: 'exemple@domaine.com',
                              ),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_loginError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _loginError!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(
                                        () => _rememberMe = value ?? false);
                                  },
                                  activeColor: const Color(0xFFE91E63),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Se souvenir de moi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        debugPrint('Audio: Connexion en cours');
                                      },
                                      icon: const Icon(
                                        Icons.volume_up,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSocialLoginButton(
                        icon: Icons.g_mobiledata,
                        label: 'Continuer avec Google',
                        color: Colors.white,
                        textColor: Colors.black87,
                        onTap: () {
                          debugPrint('Connexion avec Google');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSocialLoginButton(
                        icon: Icons.facebook,
                        label: 'Continuer avec Facebook',
                        color: const Color(0xFF1877F2),
                        textColor: Colors.white,
                        onTap: () {
                          debugPrint('Connexion avec Facebook');
                        },
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pas encore de compte ? ',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                debugPrint('Navigation vers Inscription');
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'S\'inscrire',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loginAttempts > 0)
                        Center(
                          child: Text(
                            'Tentatives : $_loginAttempts/$_maxAttempts',
                            style: TextStyle(
                              fontSize: 12,
                              color: _loginAttempts >= 3
                                  ? Colors.red
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _usePhone = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _usePhone ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _usePhone
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: _usePhone
                          ? const Color(0xFFE91E63)
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Téléphone',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            _usePhone ? FontWeight.w600 : FontWeight.w500,
                        color: _usePhone
                            ? const Color(0xFF4A148C)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _usePhone = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_usePhone ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_usePhone
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: !_usePhone
                          ? const Color(0xFFE91E63)
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            !_usePhone ? FontWeight.w600 : FontWeight.w500,
                        color: !_usePhone
                            ? const Color(0xFF4A148C)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? error,
    String? hint,
    TextInputType? keyboardType,
  }) {
    final hasError = error != null;
    final isValid = controller.text.isNotEmpty && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => debugPrint('Audio: $label'),
              icon: const Icon(Icons.volume_up,
                  size: 18, color: Color(0xFFE91E63)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(
              icon,
              color: hasError
                  ? Colors.red
                  : (isValid ? Colors.green : Colors.grey),
            ),
            suffixIcon: isValid
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red
                    : (isValid ? Colors.green : Colors.grey[300]!),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFFE91E63),
                width: 2,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                error,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField() {
    final hasError = _contactError != null;
    final isValid = _phoneController.text.length >= 8 && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Numéro de téléphone',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => debugPrint('Audio: Numéro de téléphone'),
              icon: const Icon(Icons.volume_up,
                  size: 18, color: Color(0xFFE91E63)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(
                  color: hasError
                      ? Colors.red
                      : (isValid ? Colors.green : Colors.grey[300]!),
                ),
              ),
              child: DropdownButton<String>(
                value: _countryCode,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                items: ['+229', '+33', '+1', '+44'].map((code) {
                  return DropdownMenuItem(
                    value: code,
                    child: Text(code,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _countryCode = value!);
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: 'XX XX XX XX',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: hasError
                        ? Colors.red
                        : (isValid ? Colors.green : Colors.grey),
                  ),
                  suffixIcon: isValid
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(
                      color: hasError
                          ? Colors.red
                          : (isValid ? Colors.green : Colors.grey[300]!),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : const Color(0xFFE91E63),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(_contactError!,
                  style: const TextStyle(fontSize: 13, color: Colors.red)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField() {
    final hasError = _passwordError != null;
    final isValid = _passwordController.text.length >= 6 && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mot de passe',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => debugPrint('Audio: Mot de passe'),
              icon: const Icon(Icons.volume_up,
                  size: 18, color: Color(0xFFE91E63)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              color: hasError
                  ? Colors.red
                  : (isValid ? Colors.green : Colors.grey),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isValid)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
                IconButton(
                  onPressed: () {
                    setState(() => _passwordVisible = !_passwordVisible);
                  },
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red
                    : (isValid ? Colors.green : Colors.grey[300]!),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFFE91E63),
                width: 2,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                _passwordError!,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: BorderSide(
            color: color == Colors.white ? Colors.grey[300]! : color,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE91E63).withOpacity(0.2),
                  const Color(0xFF4A148C).withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFE91E63).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 36,
              color: const Color(0xFFE91E63),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
