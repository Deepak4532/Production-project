import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
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
    setState(() {
      _passwordStrength = strength.clamp(0, 1);
    });
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    try {
      final db = DatabaseHelper();
      final user = await db.getUser(email);
      if (user != null) {
        setState(() { _error = 'Email already registered.'; _loading = false; });
        _showError('Email already registered.');
        return;
      }
      await db.registerUser(username, email, hashedPassword);
      if (mounted) {
        _showSuccess('Account created successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      setState(() { _error = 'Registration failed.'; });
      _showError('Registration failed. Please try again.');
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
        title: const Text('Register'),
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
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                          child: Icon(Icons.person_add_alt_1, size: 46, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Create Account',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Let’s get you started',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                        ),
                        const SizedBox(height: 18),
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
                        if (_passwordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
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
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(_error!, style: const TextStyle(color: Colors.red)),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _loading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _register();
                                    }
                                  },
                            child: _loading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Register'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                          child: const Text('Already have an account? Login'),
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
