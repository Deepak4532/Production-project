import 'package:flutter/material.dart';
import 'package:medication/services/database_helper.dart';
import 'package:medication/services/notification_service.dart';

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

  TimeOfDay? _pickedTime;

  void _showAddReminderDialog() async {
    setState(() { _pickedTime = null; });
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(_pickedTime == null ? 'Pick Time' : _pickedTime!.format(context)),
                onPressed: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t != null) setDialogState(() { _pickedTime = t; });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _pickedTime == null
                  ? null
                  : () async {
                      final db = DatabaseHelper();
                      final medId = widget.medicationId ?? 1;
                      final meds = await db.db.then((dbClient) => dbClient.query('medications', where: 'id = ?', whereArgs: [medId]));
                      final medName = meds.isNotEmpty ? meds.first['name'] ?? '' : '';
                      final reminderId = await db.addReminderForMedication(
                        medId,
                        _pickedTime!.format(context),
                        true,
                      );
                      final now = DateTime.now();
                      var scheduled = DateTime(now.year, now.month, now.day, _pickedTime!.hour, _pickedTime!.minute);
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
                      Navigator.of(ctx).pop();
                      _loadReminders();
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteReminder(int id) async {
    final db = DatabaseHelper();
    await db.deleteReminder(id);
    await NotificationService().cancelNotification(id);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary.withOpacity(0.12), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? Center(
                    child: Text(
                      'No reminders yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(top: topPadding, left: 16, right: 16, bottom: 16),
                    itemCount: _reminders.length,
                    itemBuilder: (context, i) {
                      final reminder = _reminders[i];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            child: const Icon(Icons.alarm, color: Colors.deepPurple),
                          ),
                          title: Text(
                            reminder['time'] ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Enabled: ${reminder['enabled'] == 1 ? 'Yes' : 'No'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteReminder(reminder['id']),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
