import 'package:flutter/material.dart';
import 'package:medication/screens/medication_screen.dart';
import 'package:medication/services/database_helper.dart';

class MedicationScreenWithDoseDialog extends StatelessWidget {
  final int medicationId;
  final String medicationName;
  const MedicationScreenWithDoseDialog({Key? key, required this.medicationId, required this.medicationName}) : super(key: key);

  static Future<void> showDoseDialog(BuildContext context, int medicationId, String medicationName) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark Dose for $medicationName'),
        content: const Text('Did you take your medication?'),
        actions: [
          TextButton(
            onPressed: () async {
              final db = DatabaseHelper();
              await db.db.then((dbClient) => dbClient.insert('dose_history', {
                'medication_id': medicationId,
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
                'medication_id': medicationId,
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withOpacity(0.10), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const MedicationScreen(),
    );
  }
}