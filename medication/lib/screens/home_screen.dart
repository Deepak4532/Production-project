import 'package:flutter/material.dart';
import 'package:medication/screens/add_medication_screen.dart';
import 'package:medication/screens/profile_screen.dart';
import 'package:medication/services/database_helper.dart';
import 'package:medication/screens/reminder_screen.dart';
import 'package:medication/screens/medication_screen.dart';

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
        const Center(child: Text('Pill Recognition')), // Placeholder for pill recognition
        ProfileScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Smart Medication Reminder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary.withOpacity(0.10), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: 8),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication),
              label: 'Medications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Pill Recog.',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showUnselectedLabels: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard();

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  List<Map<String, dynamic>> _medications = [];
  Map<String, dynamic>? _nextReminder;
  bool _loading = true;

  void _showMedicationDetail(Map<String, dynamic> med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(med['name'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((med['dosage'] ?? '').toString().isNotEmpty)
              Text('Dosage: ${med['dosage']}'),
            if ((med['notes'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Notes: ${med['notes']}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final meds = await db.db.then((dbClient) => dbClient.query('medications', orderBy: 'id DESC'));
    final reminders = await db.db.then((dbClient) => dbClient.rawQuery('SELECT reminders.*, medications.name, medications.dosage FROM reminders JOIN medications ON reminders.medication_id = medications.id ORDER BY reminders.time ASC'));
    setState(() {
      _medications = meds;
      _nextReminder = reminders.isNotEmpty ? reminders.first : null;
      _loading = false;
    });
  }

  void _openAddMedication(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddMedicationScreen(onSaved: _loadData),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Medications",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: _medications.isEmpty
                      ? const Center(child: Text('No medications added.'))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _medications.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => _showMedicationDetail(_medications[i]),
                            child: _MedicationCard(
                              name: _medications[i]['name'],
                              dosage: _medications[i]['dosage'],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Reminder',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.alarm, size: 32),
                    title: Text(_nextReminder != null ? '${_nextReminder!['name']} ${_nextReminder!['dosage'] ?? ''}' : 'No reminders'),
                    subtitle: Text(_nextReminder != null ? _nextReminder!['time'] : ''),
                    trailing: _nextReminder != null
                        ? IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: _loadData,
                          )
                        : null,
                    onTap: _nextReminder != null && _nextReminder!['medication_id'] != null
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReminderScreen(medicationId: _nextReminder!['medication_id']),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickActionButton(
                      icon: Icons.add,
                      label: 'Add Medication',
                      onTap: () => _openAddMedication(context),
                    ),
                    _QuickActionButton(
                      icon: Icons.camera_alt,
                      label: 'Recognize Pill',
                      onTap: () {
                        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        if (homeState != null) {
                          homeState.setState(() {
                            homeState._selectedIndex = 2;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}

class _MedicationCard extends StatelessWidget {
  final String name;
  final String? dosage;
  const _MedicationCard({Key? key, required this.name, this.dosage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name),
          const SizedBox(height: 8),
          Text(dosage ?? ''),
          const Spacer(),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class MedicationRemindersTab extends StatefulWidget {
  const MedicationRemindersTab({Key? key}) : super(key: key);
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
    final meds = await db.db.then((dbClient) => dbClient.query('medications', orderBy: 'id DESC'));
    setState(() {
      _medications = meds;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders by Medication')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _medications.length,
              itemBuilder: (context, i) {
                final med = _medications[i];
                return ListTile(
                  leading: const Icon(Icons.medication),
                  title: Text(med['name'] ?? ''),
                  subtitle: Text(med['dosage'] ?? ''),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReminderScreen(medicationId: med['id']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}