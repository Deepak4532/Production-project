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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.person, size: 56),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _username ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Profile'),
                          onTap: () {},
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notifications'),
                          onTap: () {},
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout'),
                          onTap: () async {
                            await SessionManager.clearUserSession();
                            if (context.mounted) {
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
    );
  }
}
