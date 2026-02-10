import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nonvis/config.dart';
import 'package:nonvis/screens/login_page.dart';
import 'package:nonvis/screens/profile_setup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _secureStorage = const FlutterSecureStorage();

  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _usePhone = true;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _isLoading = false;
  
  String? _nameError;
  String? _contactError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _registrationError;
  
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  
  String _countryCode = '+229';
  
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
    
    _nameController.addListener(_validateName);
    _phoneController.addListener(_validateContact);
    _emailController.addListener(_validateContact);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      if (_nameController.text.isEmpty) {
        _nameError = null;
      } else if (_nameController.text.length < 3) {
        _nameError = 'Le nom doit contenir au moins 3 caractères';
      } else {
        _nameError = null;
      }
      _registrationError = null;
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
      _registrationError = null;
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    
    setState(() {
      if (password.isEmpty) {
        _passwordError = null;
        _passwordStrength = PasswordStrength.weak;
      } else if (password.length < 6) {
        _passwordError = 'Minimum 6 caractères';
        _passwordStrength = PasswordStrength.weak;
      } else {
        _passwordError = null;
        _passwordStrength = _calculatePasswordStrength(password);
      }
      _registrationError = null;
    });
    
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  void _validateConfirmPassword() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = null;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Les mots de passe ne correspondent pas';
      } else {
        _confirmPasswordError = null;
      }
      _registrationError = null;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    
    bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (password.length >= 10 && hasUpperCase && hasDigits && hasSpecialChar) {
      return PasswordStrength.strong;
    } else if (password.length >= 8 && (hasUpperCase || hasDigits)) {
      return PasswordStrength.medium;
    }
    
    return PasswordStrength.weak;
  }

  bool _canSubmit() {
    return _nameController.text.length >= 3 &&
           (_usePhone ? _phoneController.text.length >= 8 : _isValidEmail(_emailController.text)) &&
           _passwordController.text.length >= 6 &&
           _passwordController.text == _confirmPasswordController.text &&
           _termsAccepted &&
           _nameError == null &&
           _contactError == null &&
           _passwordError == null &&
           _confirmPasswordError == null;
  }


Future<void> _handleRegistration() async {
  if (!_canSubmit()) {
    _shakeController.forward(from: 0);
    return;
  }

  setState(() {
    _isLoading = true;
    _registrationError = null;
  });

  try {
    final fullName = _nameController.text.trim();
    final email = _usePhone ? null : _emailController.text.trim();
    final phone = _usePhone ? '$_countryCode${_phoneController.text.trim()}' : null;

    debugPrint('📡 Envoi requête register vers: $API_BASE_URL/register');
    debugPrint('📋 Name: $fullName');
    debugPrint('📋 Email: $email');
    debugPrint('📋 Phone: $phone');

    final response = await http.post(
      Uri.parse('$API_BASE_URL/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': fullName,
        'email': email,
        'phone': phone,
        'password': _passwordController.text,
        'confirm_password': _confirmPasswordController.text,
      }),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Délai d\'attente dépassé'),
    );

    debugPrint('Réponse serveur: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (!mounted) return;

    final status = response.statusCode;
    final data = response.body.isNotEmpty 
        ? jsonDecode(response.body) as Map<String, dynamic> 
        : {};

    if (status == 200 || status == 201) {
      final token = data['token'] as String?;
      debugPrint('🔑 Token reçu: ${token?.substring(0, 20)}...');

      if (token != null && token.isNotEmpty) {
        await _secureStorage.write(key: 'userToken', value: token);
        
        final savedToken = await _secureStorage.read(key: 'userToken');
        debugPrint(' Token sauvegardé: ${savedToken?.substring(0, 20)}...');
      } else {
        debugPrint(' Aucun token reçu - création token temporaire');
        await _secureStorage.write(
          key: 'userToken', 
          value: 'temp_token_${DateTime.now().millisecondsSinceEpoch}'
        );
      }

      final prefs = await SharedPreferences.getInstance();
      String savedName = fullName;
      
      if (data['user'] != null && data['user']['name'] != null) {
        savedName = data['user']['name'] as String;
      } else if (data['name'] != null) {
        savedName = data['name'] as String;
      }
      
      await prefs.setString(PrefKeys.userName, savedName);
      await prefs.setBool(
        PrefKeys.isProfileCompleted, 
        data['user']?['profileCompleted'] == true
      );

      debugPrint('Données sauvegardées - Nom: $savedName');

      HapticFeedback.mediumImpact();

      if (mounted) {
        _showSuccessSnackBar('Compte créé avec succès !');
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
            );
          }
        });
      }
    } else {
      final message = data['error'] ?? data['message'] ?? 'Erreur lors de l\'inscription';
      _handleRegistrationError(message);
    }
  } on http.ClientException {
    _handleRegistrationError('Erreur de connexion au serveur');
  } on FormatException {
    _handleRegistrationError('Réponse serveur invalide');
  } catch (e) {
    debugPrint(' Erreur registration: $e');
    _handleRegistrationError('Erreur inattendue: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  void _handleRegistrationError(String message) {
    setState(() {
      _registrationError = message;
    });
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFF4A148C)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Créer mon compte',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A148C),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Rejoins la communauté NONVI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => debugPrint('Audio: Créer mon compte'),
                            icon: const Icon(Icons.volume_up, color: Color(0xFFE91E63)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      if (_registrationError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _registrationError!,
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
                      
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nom et Prénom',
                        icon: Icons.person_outline,
                        error: _nameError,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildContactToggle(),
                      
                      const SizedBox(height: 16),
                      
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
                      
                      _buildPasswordField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                        isVisible: _passwordVisible,
                        onToggleVisibility: () {
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                        error: _passwordError,
                        isValid: _passwordError == null && _passwordController.text.isNotEmpty,
                        hasError: _passwordError != null,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildPasswordStrengthIndicator(),
                      
                      const SizedBox(height: 8),
                      
                      _buildPasswordRequirements(),
                      
                      const SizedBox(height: 20),
                      
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirme ton mot de passe',
                        isVisible: _confirmPasswordVisible,
                        onToggleVisibility: () {
                          setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
                        },
                        error: _confirmPasswordError, 
                        isValid: _confirmPasswordError == null && _confirmPasswordController.text.isNotEmpty, 
                        hasError: _confirmPasswordError != null,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildTermsCheckbox(),
                      
                      const SizedBox(height: 32),
                      
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value * 
                              (_shakeController.status == AnimationStatus.forward ? 1 : -1), 0),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: _canSubmit() ? 4 : 0,
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
                                : const Text(
                                    'Créer mon compte',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
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
                      
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tu as déjà un compte ? ',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Se connecter',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? error,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
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
              icon: const Icon(Icons.volume_up, size: 18, color: Color(0xFFE91E63)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isValid)
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                icon,
                color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey),
              ),
              suffixIcon: isValid
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : (hasError ? const Icon(Icons.error, color: Colors.red) : null),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey[300]!),
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
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                error,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
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
                      color: _usePhone ? const Color(0xFFE91E63) : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Téléphone',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _usePhone ? FontWeight.w600 : FontWeight.w500,
                        color: _usePhone ? const Color(0xFF4A148C) : Colors.grey[600],
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
                      color: !_usePhone ? const Color(0xFFE91E63) : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: !_usePhone ? FontWeight.w600 : FontWeight.w500,
                        color: !_usePhone ? const Color(0xFF4A148C) : Colors.grey[600],
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
              icon: const Icon(Icons.volume_up, size: 18, color: Color(0xFFE91E63)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isValid)
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
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
                    color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey[300]!),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _countryCode,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: ['+229', '+33', '+1', '+44'].map((code) {
                    return DropdownMenuItem(
                      value: code,
                      child: Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey),
                    ),
                    suffixIcon: isValid
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : (hasError ? const Icon(Icons.error, color: Colors.red) : null),
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
                        color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey[300]!),
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
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                _contactError!,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isVisible,
    required bool isValid,
    required bool hasError,
    required String label,
    required VoidCallback onToggleVisibility,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A148C),
              ),
            ),
            IconButton(
              onPressed: () => debugPrint('Audio: $label'),
              icon: const Icon(
                Icons.volume_up,
                size: 18,
                color: Color(0xFFE91E63),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggleVisibility,
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
                color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey[300]!),
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
                error ?? '',
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    Color color;
    String label;
    double width;
    
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        color = Colors.red;
        label = 'Faible';
        width = 0.33;
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        label = 'Moyen';
        width = 0.66;
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        label = 'Fort';
        width = 1.0;
        break;
    }
    
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: width,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();
    
    final password = _passwordController.text;
    final hasMinLength = password.length >= 6;
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement('Au moins 6 caractères', hasMinLength),
        const SizedBox(height: 4),
        _buildRequirement('Inclure un chiffre (recommandé)', hasDigit),
        const SizedBox(height: 4),
        _buildRequirement('Inclure une majuscule (recommandé)', hasUpperCase),
      ],
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: met ? Colors.green : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (value) {
            setState(() => _termsAccepted = value ?? false);
          },
          activeColor: const Color(0xFFE91E63),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        _showTermsDialog('Conditions d\'utilisation');
                      },
                      child: const Text(
                        'Conditions d\'utilisation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' et la '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        _showTermsDialog('Politique de confidentialité');
                      },
                      child: const Text(
                        'Politique de confidentialité',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C),
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Contenu des $title...\n\n'
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fermer',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

enum PasswordStrength { weak, medium, strong }