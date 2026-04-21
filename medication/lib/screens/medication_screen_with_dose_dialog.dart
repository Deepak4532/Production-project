import 'package:flutter/material.dart';
import 'package:medication/screens/medication_screen.dart';
import 'package:medication/services/database_helper.dart';

class MedicationScreenWithDoseDialog extends StatefulWidget {
  final int medicationId;
  final String medicationName;
  const MedicationScreenWithDoseDialog({Key? key, required this.medicationId, required this.medicationName}) : super(key: key);

  @override
  State<MedicationScreenWithDoseDialog> createState() => _MedicationScreenWithDoseDialogState();
}

class _MedicationScreenWithDoseDialogState extends State<MedicationScreenWithDoseDialog> {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Mark Dose for ${widget.medicationName}'),
            content: const Text('Did you take your medication?'),
            actions: [
              TextButton(
                onPressed: () async {
                  final db = DatabaseHelper();
                  await db.db.then((dbClient) => dbClient.insert('dose_history', {
                    'medication_id': widget.medicationId,
                    'taken': 1,
                    'timestamp': DateTime.now().toIso8601String(),
                  }));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Taken'),
              ),
              TextButton(
                onPressed: () async {
                  final db = DatabaseHelper();
                  await db.db.then((dbClient) => dbClient.insert('dose_history', {
                    'medication_id': widget.medicationId,
                    'taken': 0,
                    'timestamp': DateTime.now().toIso8601String(),
                  }));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Not Taken'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MedicationScreen();
  }
}