import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication/screens/add_medication_screen.dart';

void main() {
  group('UI/UX Interface Testing (Main App Pages)', () {
    Widget createWidgetUnderTest() {
      return const MaterialApp(
        home: AddMedicationScreen(),
      );
    }

    testWidgets('Add Medication Screen renders form elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify the App Bar title
      expect(find.text('Add Medication'), findsOneWidget);

      // Verify the input fields exist
      expect(find.text('Medication Name'), findsOneWidget);
      expect(find.text('Dosage'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Duration (days)'), findsOneWidget);

      // Verify the SwitchListTile exists
      expect(find.text('Enable Reminder'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);

      // Verify the Time Picker exists
      expect(find.text('Select Reminder Time'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      // Verify the Save button exists
      expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
    });

    testWidgets('Add Medication Screen form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the save button with empty fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify the validation error shows up
      expect(find.text('Required'), findsOneWidget);
    });
  });
}
