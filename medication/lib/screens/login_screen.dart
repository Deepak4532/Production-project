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
        return;
      }
      // Save session
      await SessionManager.saveUserSession(email);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() { _error = 'Login failed.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                  child: _loading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('Login'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
