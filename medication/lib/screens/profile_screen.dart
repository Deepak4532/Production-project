import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import '../services/database_helper.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _email;
  bool _loading = true;
  bool _saving = false;

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final email = await SessionManager.getUserSession();
      if (email != null) {
        final user = await DatabaseHelper().getUser(email);
        setState(() {
          _username = user?['username'] ?? '';
          _email = user?['email'] ?? '';
          _loading = false;
        });
      } else {
        setState(() {
          _username = '';
          _email = '';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _username = '';
        _email = '';
        _loading = false;
      });
      _showMessage('Unable to load profile data.', isError: true);
    }
  }

  void _showEditProfileDialog() {
    final usernameController = TextEditingController(text: _username);
    final emailController = TextEditingController(text: _email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              enabled: false, // Email is not editable for now
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_saving) return;
              final newUsername = usernameController.text.trim();
              if (newUsername.isNotEmpty && _email != null) {
                setState(() => _saving = true);
                final db = DatabaseHelper();
                final dbClient = await db.db;
                await dbClient.update(
                  'users',
                  {'username': newUsername},
                  where: 'email = ?',
                  whereArgs: [_email],
                );
                setState(() {
                  _username = newUsername;
                  _saving = false;
                });
                _showMessage('Profile updated successfully.');
                Navigator.of(ctx).pop();
              } else {
                _showMessage('Username cannot be empty.', isError: true);
              }
            },
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withOpacity(0.16), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Hero(
                      tag: 'profile_avatar',
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 64, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _username ?? '',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _email ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 36),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Edit Profile'),
                            subtitle: const Text('Update your display name'),
                            onTap: _showEditProfileDialog,
                          ),
                          const Divider(height: 0),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Logout'),
                            subtitle: const Text('Sign out from this device'),
                            onTap: () async {
                              await SessionManager.clearUserSession();
                              if (context.mounted) {
                                _showMessage('Logged out successfully.');
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
