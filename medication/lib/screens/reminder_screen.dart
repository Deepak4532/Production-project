import 'package:flutter/material.dart';
import 'package:medication/services/database_helper.dart';
import 'package:medication/services/notification_service.dart';
import 'package:medication/screens/medication_screen_with_dose_dialog.dart';

class ReminderScreen extends StatefulWidget {
  final int? medicationId; // Optional: filter reminders for a medication
  const ReminderScreen({Key? key, this.medicationId}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final db = DatabaseHelper();
    List<Map<String, dynamic>> reminders;
    if (widget.medicationId != null) {
      reminders = await db.db.then((dbClient) => dbClient.query(
        'reminders',
        where: 'medication_id = ?',
        whereArgs: [widget.medicationId],
        orderBy: 'time ASC',
      ));
    } else {
      reminders = await db.getReminders();
    }
    setState(() {
      _reminders = reminders;
      _loading = false;
    });
  }

  void _showAddReminderDialog() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final db = DatabaseHelper();
      final medId = widget.medicationId ?? 1;
      // Get medication name
      final meds = await db.db.then((dbClient) => dbClient.query('medications', where: 'id = ?', whereArgs: [medId]));
      final medName = meds.isNotEmpty ? meds.first['name'] ?? '' : '';
      final reminderId = await db.addReminderForMedication(
        medId,
        picked.format(context),
        true,
      );
      // Schedule notification
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await NotificationService().scheduleNotification(
        id: reminderId,
        title: 'Time to take your medicine',
        body: 'It\'s time to take $medName',
        scheduledTime: scheduled,
        payload: '$medId:$reminderId:$medName',
      );
      _loadReminders();
    }
  }

  void _deleteReminder(int id) async {
    final db = DatabaseHelper();
    await db.deleteReminder(id);
    await NotificationService().cancelNotification(id);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _reminders.length,
              itemBuilder: (context, i) {
                final reminder = _reminders[i];
                return ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(reminder['time'] ?? ''),
                  subtitle: Text('Enabled: ${reminder['enabled'] == 1 ? 'Yes' : 'No'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteReminder(reminder['id']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
