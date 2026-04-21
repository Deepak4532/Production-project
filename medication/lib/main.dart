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
    _checkSession();
  }

  Future<void> _checkSession() async {
    final email = await SessionManager.getUserSession();
    if (mounted) {
      if (email != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
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
