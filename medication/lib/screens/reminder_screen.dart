import 'package:flutter/material.dart';
import 'package:medication/services/database_helper.dart';
import 'package:medication/services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  final int? medicationId; // Optional: filter reminders for a medication
  const ReminderScreen({super.key, this.medicationId});

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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Add Reminder',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a time for your medication alert.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF7C3AED),
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF1A1A2E),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (t != null) setDialogState(() { _pickedTime = t; });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 12),
                      Text(
                        _pickedTime == null ? 'Select Time' : _pickedTime!.format(context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
              child: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : CustomScrollView(
              slivers: [
                // ── Modern Header ──
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reminders',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.medicationId != null ? 'Schedule for this medication' : 'Your complete medication schedule',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Reminders List ──
                _reminders.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 20,
                                    )
                                  ],
                                ),
                                child: Icon(Icons.notifications_off_rounded, color: Colors.grey.shade300, size: 64),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No reminders set',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to create a reminder',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final reminder = _reminders[i];
                              return _ReminderCard(
                                reminder: reminder,
                                onDelete: () => _deleteReminder(reminder['id']),
                              );
                            },
                            childCount: _reminders.length,
                          ),
                        ),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onDelete;

  const _ReminderCard({required this.reminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = (reminder['enabled'] as int? ?? 1) == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.alarm_rounded, color: Color(0xFF7C3AED), size: 28),
        ),
        title: Text(
          reminder['time'] ?? '',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.5,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isEnabled ? 'Active' : 'Disabled',
              style: TextStyle(
                color: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.7)),
        ),
      ),
    );
  }
}
