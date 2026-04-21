import 'package:flutter/material.dart';
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
    await db.addReminderForMedication(medId, _reminderTime!.format(context), _reminderEnabled);
    setState(() => _saving = false);
    if (widget.onSaved != null) widget.onSaved!();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Medication Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dosage'),
                onSaved: (v) => _dosage = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notes'),
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 16),
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
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
