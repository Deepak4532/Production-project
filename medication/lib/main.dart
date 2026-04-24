import 'package:medication/screens/medication_screen_with_dose_dialog.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter/material.dart';
import 'package:medication/screens/splash_screen.dart';
import 'package:medication/screens/login_screen.dart';
import 'package:medication/screens/home_screen.dart';
import 'package:medication/screens/profile_screen.dart';
import 'package:medication/screens/register_screen.dart';
import 'services/session_manager.dart';
import 'package:medication/services/notification_service.dart';
import 'package:medication/services/notification_service.dart' show navigatorKey;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/mark-dose': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MedicationScreenWithDoseDialog(
            medicationId: args['medicationId'],
            medicationName: args['medicationName'],
          );
        },
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
      // After session navigation, check for notification payload and navigate if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final payload = NotificationService.initialNotificationPayload;
        if (payload != null) {
          debugPrint('[RootScreen] Cold start notification payload: $payload');
          final parts = payload.split(':');
          if (parts.length >= 3) {
            final medId = int.tryParse(parts[0]);
            final medName = parts.sublist(2).join(':');
            if (medId != null) {
              navigatorKey.currentState?.popUntil((route) => route.isFirst);
              navigatorKey.currentState?.pushNamed(
                '/mark-dose',
                arguments: {
                  'medicationId': medId,
                  'medicationName': medName,
                },
              );
              NotificationService.initialNotificationPayload = null;
            } else {
              debugPrint('[RootScreen] Invalid medId in payload: $payload');
            }
          } else {
            debugPrint('[RootScreen] Invalid payload format: $payload');
          }
        }
      });
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
