import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medication/screens/splash_screen.dart';
import 'package:medication/screens/login_screen.dart';
import 'package:medication/screens/home_screen.dart';
import 'package:medication/screens/profile_screen.dart';
import 'package:medication/screens/register_screen.dart';
import 'package:medication/services/notification_service.dart';
import 'package:medication/services/database_helper.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set the global callback so notification taps can fire from any state
    onNotificationTapped = _handlePayload;

    // ── Native MethodChannel listener (iOS native bridge) ──
    const MethodChannel('com.medication.app/notification')
        .setMethodCallHandler((call) async {
      if (call.method == 'onNotificationTap') {
        final payload = call.arguments as String?;
        debugPrint('[MAIN] Native channel received: $payload');
        if (payload != null) _handlePayload(payload);
      }
    });

    // After first frame: check if there's a pending payload from cold-launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1500));
      _consumePendingPayload();
    });
  }

  @override
  void dispose() {
    onNotificationTapped = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 600), _consumePendingPayload);
    }
  }

  void _consumePendingPayload() {
    final payload = NotificationService.pendingPayload;
    if (payload != null) {
      NotificationService.pendingPayload = null;
      _handlePayload(payload);
    }
  }

  void _handlePayload(String payload) async {
    debugPrint('[MAIN] Handling payload: $payload');

    // Immediate visual confirmation
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Notification received: $payload'),
        duration: const Duration(seconds: 3),
      ),
    );

    final parts = payload.split(':');
    if (parts.length < 3) {
      debugPrint('[MAIN] Payload malformed, ignoring.');
      return;
    }

    final medId = int.tryParse(parts[0]);
    final medName = parts.sublist(2).join(':');
    if (medId == null) return;

    // Wait until the navigator exists
    int tries = 0;
    while (navigatorKey.currentContext == null && tries < 30) {
      await Future.delayed(const Duration(milliseconds: 300));
      tries++;
    }
    if (navigatorKey.currentContext == null) {
      debugPrint('[MAIN] Navigator context still null after waiting, giving up.');
      return;
    }

    // Extra settle time
    await Future.delayed(const Duration(milliseconds: 500));

    _showDoseDialog(medId, medName);
  }

  void _showDoseDialog(int medId, String medName) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    debugPrint('[MAIN] Showing dose dialog for medId=$medId medName=$medName');

    showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Pill icon with gradient background
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Icon(Icons.medication_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Time to take your dose!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medName,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Did you take your medication?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            // Taken button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    Navigator.of(sheetCtx).pop();
                    final db = await DatabaseHelper().db;
                    await db.insert('dose_history', {
                      'medication_id': medId,
                      'taken': 1,
                      'timestamp': DateTime.now().toIso8601String(),
                    });
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Dose marked as taken!', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Yes, I took it ✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Not taken button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.red.shade50,
                ),
                onPressed: () async {
                  Navigator.of(sheetCtx).pop();
                  final db = await DatabaseHelper().db;
                  await db.insert('dose_history', {
                    'medication_id': medId,
                    'taken': 0,
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Dose marked as skipped', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                icon: Icon(Icons.close_rounded, color: Colors.red.shade600, size: 20),
                label: Text(
                  'No, I skipped it',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Smart Medication Reminder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7D3E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 1.3),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
