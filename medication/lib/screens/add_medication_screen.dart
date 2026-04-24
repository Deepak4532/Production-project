import 'package:flutter/material.dart';
import 'package:medication/services/notification_service.dart';
import 'package:medication/services/database_helper.dart';

class AddMedicationScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const AddMedicationScreen({Key? key, this.onSaved}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _dosage = '';
  String _notes = '';
  TimeOfDay? _reminderTime;
  bool _reminderEnabled = true;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _reminderTime == null) return;
    setState(() => _saving = true);
    _formKey.currentState!.save();
    final db = DatabaseHelper();
    final medId = await db.addMedication(_name, _dosage, _notes);
    final reminderId = await db.addReminderForMedication(medId, _reminderTime!.format(context), _reminderEnabled);
    if (_reminderEnabled) {
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, _reminderTime!.hour, _reminderTime!.minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await NotificationService().scheduleNotification(
        id: reminderId,
        title: 'Time to take your medicine',
        body: 'It\'s time to take $_name',
        scheduledTime: scheduled,
        payload: '$medId:$reminderId:$_name',
      );
    }
    setState(() => _saving = false);
    if (widget.onSaved != null) widget.onSaved!();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Add Medication'),
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
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Medication Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onSaved: (v) => _name = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => _dosage = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => _notes = v ?? '',
                      ),
                      const SizedBox(height: 18),
                      SwitchListTile(
                        title: const Text('Enable Reminder'),
                        value: _reminderEnabled,
                        onChanged: (v) => setState(() => _reminderEnabled = v),
                      ),
                      ListTile(
                        title: Text(_reminderTime == null
                            ? 'Select Reminder Time'
                            : 'Reminder Time: ${_reminderTime!.format(context)}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => _reminderTime = picked);
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
