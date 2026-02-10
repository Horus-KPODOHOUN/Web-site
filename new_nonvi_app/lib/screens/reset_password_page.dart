import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nonvis/config.dart';
import 'package:nonvis/screens/login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordPage({
    Key? key,
    required this.email,
    required this.token,
  }) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _errorMessage;
  
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  bool _resetSuccess = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateNewPassword() {
    final password = _newPasswordController.text;
    
    setState(() {
      if (password.isEmpty) {
        _newPasswordError = null;
        _passwordStrength = PasswordStrength.weak;
      } else if (password.length < 6) {
        _newPasswordError = 'Minimum 6 caractères';
        _passwordStrength = PasswordStrength.weak;
      } else {
        _newPasswordError = null;
        _passwordStrength = _calculatePasswordStrength(password);
      }
      _errorMessage = null;
    });
    
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  void _validateConfirmPassword() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = null;
      } else if (_newPasswordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Les mots de passe ne correspondent pas';
      } else {
        _confirmPasswordError = null;
      }
      _errorMessage = null;
    });
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
    return _newPasswordController.text.length >= 6 &&
           _newPasswordController.text == _confirmPasswordController.text &&
           _newPasswordError == null &&
           _confirmPasswordError == null;
  }

  Future<void> _resetPassword() async {
    if (!_canSubmit()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'token': widget.token,
          'newPassword': _newPasswordController.text,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Délai d\'attente dépassé'),
      );

      if (!mounted) return;

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : {};

      if (response.statusCode == 200) {
        setState(() => _resetSuccess = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mot de passe réinitialisé avec succès !',
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
            duration: const Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        });
      } else {
        final message = data['error'] ?? data['message'] ?? 'Erreur lors de la réinitialisation';
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur de connexion: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nouveau mot de passe',
          style: TextStyle(
            color: Color(0xFF4A148C),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

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
                    Icons.lock_reset,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (!_resetSuccess) ...[
                const Text(
                  'Créer un nouveau mot de passe',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Ton nouveau mot de passe doit être différent de l\'ancien.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
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
                            _errorMessage!,
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

                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Nouveau mot de passe',
                  isVisible: _newPasswordVisible,
                  onToggleVisibility: () {
                    setState(() => _newPasswordVisible = !_newPasswordVisible);
                  },
                  onChanged: (_) => _validateNewPassword(),
                  error: _newPasswordError,
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
                  onChanged: (_) => _validateConfirmPassword(),
                  error: _confirmPasswordError,
                ),

                const SizedBox(height: 32),

                // Bouton Réinitialiser
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
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
                            'Réinitialiser le mot de passe',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // Message de succès
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mot de passe réinitialisé !',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ton mot de passe a été modifié avec succès. Tu peux maintenant te connecter avec ton nouveau mot de passe.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        color: Color(0xFFE91E63),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Redirection vers la connexion...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton manuel vers connexion
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE91E63), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Aller à la connexion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required Function(String) onChanged,
    String? error,
  }) {
    final hasError = error != null;
    final isValid = controller.text.length >= 6 && !hasError;

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
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey),
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
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
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
                error,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_newPasswordController.text.isEmpty) return const SizedBox.shrink();

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
    if (_newPasswordController.text.isEmpty) return const SizedBox.shrink();

    final password = _newPasswordController.text;
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
}

enum PasswordStrength { weak, medium, strong }