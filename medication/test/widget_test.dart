import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medication/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders branding correctly', (WidgetTester tester) async {
    // 1. Setup mock preferences
    SharedPreferences.setMockInitialValues({});

    // 2. Build our app and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login Screen')),
          '/home': (context) => const Scaffold(body: Text('Home Screen')),
        },
      ),
    );

    // 3. Verify that the branding text is on the screen
    expect(find.text('Medication Pro'), findsOneWidget);
    expect(find.text('Your health, prioritized.'), findsOneWidget);
    
    // Verify the loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 4. Let the animation and timer finish (2 seconds)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 5. Verify it navigated to the Login Screen (since mock preferences are empty)
    expect(find.text('Login Screen'), findsOneWidget);
  });
}
