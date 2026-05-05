import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import '../services/database_helper.dart';
import '../services/google_sign_in_service.dart';
import 'medication_history_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _email;
  int _medicationCount = 0;
  int _reminderCount = 0;
  bool _loading = true;
  bool _saving = false;
  String? _photoUrl;
  List<Map<String, dynamic>> _doseHistory = [];

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
      final db = DatabaseHelper();
      final dbClient = await db.db;

      if (email != null) {
        final user = await db.getUser(email);
        final medications = await dbClient.query('medications');
        final reminders = await dbClient.query('reminders');
        final doseHistory = await dbClient.query('dose_history', orderBy: 'timestamp DESC', limit: 50);

        // Check for Google account details
        final googleService = GoogleSignInService();
        final googleUser = googleService.currentUser;
        
        setState(() {
          _username = user?['username'] ?? user?['name'] ?? 'User';
          _email = user?['email'] ?? '';
          _photoUrl = googleUser?.photoUrl; // Store the Google avatar URL
          _medicationCount = medications.length;
          _reminderCount = reminders.length;
          _doseHistory = doseHistory;
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

  int _getDosesTaken() {
    return _doseHistory.where((d) => d['taken'] == 1).length;
  }

  int _getDosesMissed() {
    return _doseHistory.where((d) => d['taken'] == 0).length;
  }

  void _showEditProfileDialog() {
    final usernameController = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update your display name below.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF7C3AED)),
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
                if (mounted) Navigator.of(ctx).pop();
              } else {
                _showMessage('Username cannot be empty.', isError: true);
              }
            },
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : CustomScrollView(
              slivers: [
                // ── Modern Header ──
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Avatar with Edit Button
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                                  child: _photoUrl == null 
                                    ? Icon(Icons.person_rounded, size: 65, color: const Color(0xFF7C3AED).withOpacity(0.8))
                                    : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showEditProfileDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF7C3AED)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _username ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Mini Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatItem(label: 'Medications', value: _medicationCount.toString()),
                              Container(width: 1, height: 24, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                              _StatItem(label: 'Reminders', value: _reminderCount.toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Settings Sections ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        "Account Settings",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 16),
                      _ProfileMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile',
                        subtitle: 'Change your display name',
                        color: const Color(0xFF7C3AED),
                        onTap: _showEditProfileDialog,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Medication History",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MedicationHistoryScreen()),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Icon(Icons.history_rounded, color: Colors.white, size: 32),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'View Full History',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_doseHistory.length} total record${_doseHistory.length == 1 ? '' : 's'}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade400, size: 20),
                                  ],
                                ),
                              ),
                              Container(
                                height: 1,
                                color: Colors.grey.shade100,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatCard(
                                      label: 'Taken',
                                      value: _getDosesTaken(),
                                      color: const Color(0xFF10B981),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: Colors.grey.shade200,
                                    ),
                                    _StatCard(
                                      label: 'Missed',
                                      value: _getDosesMissed(),
                                      color: Colors.redAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Account",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 16),
                      _ProfileMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        subtitle: 'Sign out from this device',
                        color: Colors.redAccent,
                        onTap: () async {
                          await SessionManager.clearUserSession();
                          try {
                            await GoogleSignInService().signOut();
                          } catch (e) {
                            debugPrint('Google Sign-Out error: $e');
                          }
                          if (context.mounted) {
                            _showMessage('Logged out successfully.');
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
      ),
    );
  }
}
