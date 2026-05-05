import 'package:flutter/material.dart';
import 'package:medication/screens/add_medication_screen.dart';
import 'package:medication/screens/profile_screen.dart';
import 'package:medication/services/database_helper.dart';
import 'package:medication/screens/reminder_screen.dart';
import 'package:medication/screens/medication_screen.dart';
import 'package:medication/screens/pill_recognition_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
        const _HomeDashboard(),
        const MedicationScreen(),
        const MedicationRemindersTab(),
        const PillRecognitionScreen(),
        ProfileScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF7C3AED),
            unselectedItemColor: const Color(0xFF9CA3AF),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Medications'),
              BottomNavigationBarItem(icon: Icon(Icons.alarm_rounded), label: 'Reminders'),
              BottomNavigationBarItem(icon: Icon(Icons.camera_alt_rounded), label: 'Pill Scan'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HOME DASHBOARD
// ─────────────────────────────────────────────
class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard();

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final meds = await db.db.then((d) => d.query('medications', orderBy: 'id DESC'));
    final reminders = await db.db.then((d) => d.rawQuery(
          'SELECT reminders.*, medications.name, medications.dosage '
          'FROM reminders '
          'JOIN medications ON reminders.medication_id = medications.id '
          'ORDER BY reminders.time ASC',
        ));
    if (mounted) {
      setState(() {
        _medications = meds;
        _reminders = reminders;
        _loading = false;
      });
    }
  }

  void _openAddMedication() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddMedicationScreen(onSaved: _loadData),
    ));
  }

  void _showMedicationDetail(Map<String, dynamic> med) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      if ((med['dosage'] ?? '').toString().isNotEmpty)
                        Text(med['dosage'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            if ((med['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes_rounded, color: Color(0xFF7C3AED), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(med['notes'], style: const TextStyle(fontSize: 14, color: Color(0xFF374151)))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good Morning' : now.hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
        : CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting 👋',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Your Medications',
                                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _loadData,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Summary pills
                          Row(
                            children: [
                              _StatChip(icon: Icons.medication_rounded, label: '${_medications.length} Medications'),
                              const SizedBox(width: 10),
                              _StatChip(icon: Icons.alarm_rounded, label: '${_reminders.length} Reminders'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Quick Actions ──
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickAction(
                          icon: Icons.add_rounded,
                          label: 'Add Med',
                          color: const Color(0xFF7C3AED),
                          onTap: _openAddMedication,
                        ),
                        _QuickAction(
                          icon: Icons.alarm_rounded,
                          label: 'Reminders',
                          color: const Color(0xFF0EA5E9),
                          onTap: () {
                            final hs = context.findAncestorStateOfType<_HomeScreenState>();
                            hs?.setState(() => hs._selectedIndex = 2);
                          },
                        ),
                        _QuickAction(
                          icon: Icons.camera_alt_rounded,
                          label: 'Scan Pill',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            final hs = context.findAncestorStateOfType<_HomeScreenState>();
                            hs?.setState(() => hs._selectedIndex = 3);
                          },
                        ),
                        _QuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: 'History',
                          color: const Color(0xFFF59E0B),
                          onTap: () {
                            final hs = context.findAncestorStateOfType<_HomeScreenState>();
                            hs?.setState(() => hs._selectedIndex = 1);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Today's Medications heading ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Row(
                    children: [
                      const Text(
                        "Today's Medications",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          final hs = context.findAncestorStateOfType<_HomeScreenState>();
                          hs?.setState(() => hs._selectedIndex = 1);
                        },
                        child: const Text('See all', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Horizontal Medication Cards ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: _medications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication_rounded, color: Colors.grey.shade300, size: 36),
                              const SizedBox(height: 8),
                              Text('No medications yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: _medications.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => _MedCard(
                            med: _medications[i],
                            onTap: () => _showMedicationDetail(_medications[i]),
                          ),
                        ),
                ),
              ),

              // ── Reminders heading ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Upcoming Reminders',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          final hs = context.findAncestorStateOfType<_HomeScreenState>();
                          hs?.setState(() => hs._selectedIndex = 2);
                        },
                        child: const Text('See all', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Scrollable Reminder List ──
              _reminders.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.alarm_off_rounded, color: Colors.grey.shade300, size: 42),
                              const SizedBox(height: 10),
                              Text('No reminders scheduled', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final r = _reminders[i];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                            child: _ReminderCard(reminder: r),
                          );
                        },
                        childCount: _reminders.length,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
  }
}

// ─────────────────────────────────────────────
//  STAT CHIP (in header)
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUICK ACTION BUTTON
// ─────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MEDICATION CARD (horizontal scroll)
// ─────────────────────────────────────────────
class _MedCard extends StatelessWidget {
  final Map<String, dynamic> med;
  final VoidCallback onTap;
  const _MedCard({required this.med, required this.onTap});

  static const _gradients = [
    [Color(0xFF7C3AED), Color(0xFF4F46E5)],
    [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = (med['id'] as int? ?? 0) % _gradients.length;
    final colors = _gradients[idx];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medication_rounded, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med['name'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((med['dosage'] ?? '').toString().isNotEmpty)
                  Text(
                    med['dosage'],
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REMINDER CARD (vertical list)
// ─────────────────────────────────────────────
class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final isEnabled = (reminder['enabled'] as int? ?? 1) == 1;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReminderScreen(medicationId: reminder['medication_id']),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isEnabled ? const Color(0xFFEDE9FE) : Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEnabled ? const Color(0xFFF5F3FF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.alarm_rounded,
                color: isEnabled ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder['name'] ?? 'Medication',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isEnabled ? const Color(0xFF1A1A2E) : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        reminder['time'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                      if ((reminder['dosage'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('• ${reminder['dosage']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isEnabled ? const Color(0xFFEDE9FE) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isEnabled ? 'Active' : 'Off',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REMINDERS TAB (tab 2)
// ─────────────────────────────────────────────
class MedicationRemindersTab extends StatefulWidget {
  const MedicationRemindersTab({super.key});
  @override
  State<MedicationRemindersTab> createState() => _MedicationRemindersTabState();
}

class _MedicationRemindersTabState extends State<MedicationRemindersTab> {
  List<Map<String, dynamic>> _medications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    final db = DatabaseHelper();
    final meds = await db.db.then((d) => d.query('medications', orderBy: 'id DESC'));
    if (mounted) {
      setState(() {
        _medications = meds;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Reminders', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : _medications.isEmpty
              ? const Center(child: Text('No medications added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _medications.length,
                  itemBuilder: (context, i) {
                    final med = _medications[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medication_rounded, color: Colors.white, size: 22),
                        ),
                        title: Text(med['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        subtitle: Text(med['dosage'] ?? '', style: TextStyle(color: Colors.grey.shade500)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF7C3AED)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ReminderScreen(medicationId: med['id'])),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}