import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/database_helper.dart';
import '../services/session_manager.dart';
import '../services/google_sign_in_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  double _passwordStrength = 0.0;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
    );
  }

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 6) strength += 0.3;
    if (RegExp(r"[A-Z]").hasMatch(password)) strength += 0.2;
    if (RegExp(r"[0-9]").hasMatch(password)) strength += 0.2;
    if (RegExp(r"[!@#\$&*~]").hasMatch(password)) strength += 0.3;
    setState(() { _passwordStrength = strength.clamp(0, 1); });
  }

  Future<void> _login() async {
    setState(() { _loading = true; });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    try {
      final db = DatabaseHelper();
      final user = await db.getUser(email);
      if (user == null || user['password'] != hashedPassword) {
        _showError('Invalid email or password.');
        setState(() { _loading = false; });
        return;
      }
      // Save session
      await SessionManager.saveUserSession(email);
      if (mounted) {
        _showSuccess('Login successful!');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      _showError('Login failed.');
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _loading = true; });
    try {
      _showError('Testing Google Sign-In setup...');
      print('🔵 [LOGIN] Attempting Google Sign-In...');
      
      try {
        final googleSignIn = GoogleSignInService();
        print('✅ [LOGIN] GoogleSignInService created');
        
        final googleUser = await googleSignIn.signInWithGoogle();
        print('✅ [LOGIN] Google Sign-In returned: ${googleUser?.email}');
        
        if (googleUser != null) {
          // Save session
          await SessionManager.saveUserSession(googleUser.email);
          if (mounted) {
            _showSuccess('Google login successful!');
            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          _showError('Google Sign-In was cancelled');
        }
      } catch (e) {
        String errorMsg = e.toString();
        _showError('Google Error: $errorMsg');
        print('❌ [LOGIN] Google Sign-In Error: $e');
        print('❌ [LOGIN] Error Type: ${e.runtimeType}');
        print('❌ [LOGIN] Stack trace:');
        print(e);
      }
    } catch (e) {
      _showError('Unexpected error: ${e.toString()}');
      print('❌ [LOGIN] Unexpected error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Immersive Background ──
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
          ),

          // ── Login Form ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // App Branding
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(Icons.medication_rounded, size: 64, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Medication Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your health, prioritized.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please sign in to your account',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            obscureText: _obscurePassword,
                            onChanged: _checkPasswordStrength,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF7C3AED)),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                          ),

                          // Strength Meter
                          if (_passwordController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF5F3FF),
                                  color: _passwordStrength > 0.7
                                      ? const Color(0xFF10B981)
                                      : _passwordStrength > 0.4
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                onPressed: _loading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) _login();
                                      },
                                child: _loading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade200)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('or continue with', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade200)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Google Login
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade200),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: _loading ? null : _loginWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login_rounded, color: Color(0xFF7C3AED), size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Google Account',
                                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
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
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7C3AED)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F3FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ],
    );
  }
}
