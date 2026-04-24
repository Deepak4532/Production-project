import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/database_helper.dart';
import '../services/session_manager.dart';


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
  String? _error;
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
    setState(() { _loading = true; _error = null; });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    try {
      final db = DatabaseHelper();
      final user = await db.getUser(email);
      if (user == null || user['password'] != hashedPassword) {
        setState(() { _error = 'Invalid email or password.'; _loading = false; });
        _showError('Invalid email or password.');
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
      setState(() { _error = 'Login failed.'; });
      _showError('Login failed.');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withOpacity(0.18), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Card(
                elevation: 12,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App logo or illustration
                        Hero(
                          tag: 'app_logo',
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                            child: Icon(Icons.medication, size: 48, color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome Back',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                          ),
                          obscureText: _obscurePassword,
                          onChanged: _checkPasswordStrength,
                          validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                        ),
                        // Password strength meter
                        if (_passwordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(
                              value: _passwordStrength,
                              minHeight: 5,
                              backgroundColor: Colors.grey[300],
                              color: _passwordStrength > 0.7
                                  ? Colors.green
                                  : _passwordStrength > 0.4
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(_error!, style: const TextStyle(color: Colors.red)),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              elevation: 2,
                            ),
                            onPressed: _loading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _login();
                                    }
                                  },
                            child: _loading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Social login placeholder
                        Row(
                          children: [
                            Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('or', style: theme.textTheme.bodySmall),
                            ),
                            Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.login, color: Colors.blue),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            onPressed: () {
                              _showError('Google login coming soon!');
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                          child: const Text("Don't have an account? Register"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
