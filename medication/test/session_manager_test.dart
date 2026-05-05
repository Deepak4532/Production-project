import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medication/services/session_manager.dart';

void main() {
  setUp(() {
    // Set a clean mock environment for SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionManager Tests', () {
    test('getUserSession should return null initially', () async {
      final session = await SessionManager.getUserSession();
      expect(session, isNull);
    });

    test('saveUserSession should save email correctly', () async {
      const testEmail = 'test@example.com';
      await SessionManager.saveUserSession(testEmail);
      
      final session = await SessionManager.getUserSession();
      expect(session, equals(testEmail));
    });

    test('clearUserSession should remove saved email', () async {
      const testEmail = 'test@example.com';
      await SessionManager.saveUserSession(testEmail);
      
      // Ensure it was saved
      var session = await SessionManager.getUserSession();
      expect(session, equals(testEmail));
      
      // Clear it
      await SessionManager.clearUserSession();
      session = await SessionManager.getUserSession();
      expect(session, isNull);
    });
  });
}
