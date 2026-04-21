import 'package:flutter/material.dart';
import 'package:medication/services/database_helper.dart';
import 'add_medication_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({Key? key}) : super(key: key);

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<Map<String, dynamic>> _medications = [];
  Map<int, List<Map<String, dynamic>>> _doseHistory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final meds = await db.db.then((dbClient) => dbClient.query('medications', orderBy: 'id DESC'));
    final Map<int, List<Map<String, dynamic>>> history = {};
    for (final med in meds) {
      final hist = await db.db.then((dbClient) => dbClient.query('dose_history', where: 'medication_id = ?', whereArgs: [med['id']], orderBy: 'timestamp DESC'));
      history[med['id'] as int] = hist;
    }
    setState(() {
      _medications = meds;
      _doseHistory = history;
      _loading = false;
    });
  }

  void _openAddMedication() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddMedicationScreen(onSaved: _loadData),
    ));
  }

  Future<void> _markDose(int medId, bool taken) async {
    final db = DatabaseHelper();
    await db.db.then((dbClient) => dbClient.insert('dose_history', {
      'medication_id': medId,
      'taken': taken ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Medications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _medications.length,
              itemBuilder: (context, i) {
                final med = _medications[i];
                final history = _doseHistory[med['id']] ?? [];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ExpansionTile(
                    title: Text(med['name'] ?? ''),
                    subtitle: Text(med['dosage'] ?? ''),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _markDose(med['id'], true),
                                child: const Text('Mark as Taken'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _markDose(med['id'], false),
                                child: const Text('Mark as Not Taken'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('History:', style: Theme.of(context).textTheme.titleSmall),
                        ),
                      ),
                      ...history.map((h) => ListTile(
                            leading: Icon(h['taken'] == 1 ? Icons.check_circle : Icons.cancel, color: h['taken'] == 1 ? Colors.green : Colors.red),
                            title: Text(h['taken'] == 1 ? 'Taken' : 'Not Taken'),
                            subtitle: Text(h['timestamp'] ?? ''),
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMedication,
        child: const Icon(Icons.add),
      ),
    );
  }
}
