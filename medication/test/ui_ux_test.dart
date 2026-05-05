import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication/screens/login_screen.dart';
import 'package:medication/screens/register_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }

  group('UI/UX Interface Testing (Login Screen)', () {
    testWidgets('Essential UI elements should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify the main header text exists
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Please sign in to your account'), findsOneWidget);

      // Verify the input fields exist by finding their hint/label text
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify the Sign In button exists
      expect(find.text('Sign In'), findsOneWidget);

      // Verify the Google Sign-In button exists
      expect(find.text('Google Account'), findsOneWidget);
    });

    testWidgets('Empty form submission triggers validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Scroll to the Sign In button
      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInBtn);
      
      // Tap the Sign In button without entering any text
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Look for inline validation errors
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Min 6 characters'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the visibility icon button
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      await tester.ensureVisible(visibilityIcon);
      expect(visibilityIcon, findsOneWidget);

      // Tap the icon to toggle visibility
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // The icon should change to visibility
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('UI/UX Interface Testing (Register Screen)', () {
    Widget createRegisterWidget() {
      return const MaterialApp(
        home: RegisterScreen(),
      );
    }

    testWidgets('Essential UI elements should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterWidget());
      await tester.pumpAndSettle();

      // Verify the main header text exists
      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Join us to manage your health better'), findsOneWidget);

      // Verify the input fields exist by finding their labels
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify the Sign In text button exists
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Empty form submission triggers validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(createRegisterWidget());
      await tester.pumpAndSettle();

      // Scroll to the Create Account button
      final createBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(createBtn);

      // Tap the Create Account button without entering any text
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Look for the validation error messages inside TextFormFields
      expect(find.text('Enter a username'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Min 6 characters'), findsOneWidget);
    });
  });
}
