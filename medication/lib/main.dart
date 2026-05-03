// import 'package:medication/screens/medication_screen_with_dose_dialog.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:medication/services/database_helper.dart';

import 'package:flutter/material.dart';
import 'package:medication/screens/splash_screen.dart';
import 'package:medication/screens/login_screen.dart';
import 'package:medication/screens/home_screen.dart';
import 'package:medication/screens/profile_screen.dart';
import 'package:medication/screens/register_screen.dart';
import 'services/session_manager.dart';
import 'package:medication/services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    NotificationService.notificationTapNotifier.addListener(_handleNotificationTap);

    // Check for initial notification after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(forceCheckInitial: true);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.notificationTapNotifier.removeListener(_handleNotificationTap);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _handleNotificationTap(forceCheckInitial: true);
      });
    }
  }

  Future<void> _showMedicationDialog(int medId, String medName) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    final context = navigator.overlay!.context;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Mark Dose for $medName'),
        content: const Text('Did you take your medication?'),
        actions: [
          TextButton(
            onPressed: () async {
              final db = await DatabaseHelper().db;
              await db.insert('dose_history', {
                'medication_id': medId,
                'taken': 1,
                'timestamp': DateTime.now().toIso8601String(),
              });
              if (mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Taken'),
          ),
          TextButton(
            onPressed: () async {
              final db = await DatabaseHelper().db;
              await db.insert('dose_history', {
                'medication_id': medId,
                'taken': 0,
                'timestamp': DateTime.now().toIso8601String(),
              });
              if (mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Not Taken'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap({bool forceCheckInitial = false}) async {
    String? payload = NotificationService.notificationTapNotifier.value;
    if (payload == null && forceCheckInitial) {
      payload = NotificationService.initialNotificationPayload;
    }

    if (payload == null) return;

    final parts = payload.split(':');
    if (parts.length < 3) return;

    final medId = int.tryParse(parts[0]);
    final medName = parts.sublist(2).join(':');

    if (medId == null) return;

    // Ensure navigator is ready
    if (navigatorKey.currentState == null || !navigatorKey.currentState!.mounted) {
      // Retry after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationTap(forceCheckInitial: true);
      return;
    }

    // Pop to home screen
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    await Future.delayed(const Duration(milliseconds: 200));

    // Show dialog
    await _showMedicationDialog(medId, medName);

    // Clear payload
    NotificationService.notificationTapNotifier.value = null;
    NotificationService.initialNotificationPayload = null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const _RootScreen(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        // Removed /mark-dose route
      },
    );
  }
}


class _RootScreen extends StatefulWidget {
  const _RootScreen();
  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkSession();
      // Notification dialog is now handled globally in MyApp
    });
  }

  Future<void> _checkSession() async {
    final email = await SessionManager.getUserSession();
    if (mounted) {
      if (email != null) {
        await navigatorKey.currentState?.pushReplacementNamed('/home');
      } else {
        await navigatorKey.currentState?.pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
