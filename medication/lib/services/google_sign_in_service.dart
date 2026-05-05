import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal();

  late GoogleSignIn _googleSignIn;
  bool _initialized = false;

  /// Initialize Google Sign-In (must be called once)
  Future<void> _initializeIfNeeded() async {
    if (_initialized) return;

    try {
      print('🔐 [DEBUG] Initializing Google Sign-In...');

      // iOS-specific initialization with error handling
      try {
        if (Platform.isIOS) {
          print('📱 [DEBUG] iOS platform detected');
          _googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
          );
          print('✅ [DEBUG] GoogleSignIn object created');
        } else {
          print('🤖 [DEBUG] Non-iOS platform detected');
          _googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
          );
        }
      } catch (e) {
        print('⚠️ [DEBUG] Error creating GoogleSignIn: $e');
        rethrow;
      }

      _initialized = true;
      print('✅ [DEBUG] Google Sign-In initialization complete');
    } catch (e) {
      print('❌ [DEBUG] Critical error initializing Google Sign-In: $e');
      print('Stack trace: $e');
      _initialized = false; // Reset flag for retry
      // Don't rethrow - let the app continue
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      // Initialize if not already done
      await _initializeIfNeeded();

      if (kDebugMode) {
        print('🔵 Starting Google Sign-In flow...');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser != null) {
        if (kDebugMode) {
          print('✅ Google Sign-In successful: ${googleUser.email}');
        }
        // User authenticated successfully
        await _handleGoogleSignIn(googleUser);
        return googleUser;
      } else {
        if (kDebugMode) {
          print('⚠️ Google Sign-In cancelled by user');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Sign-In Error: $e');
        print('Error type: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  /// Handle Google Sign-In - Create or update user in database
  Future<void> _handleGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      final db = DatabaseHelper();
      final email = googleUser.email;
      final displayName = googleUser.displayName ?? 'User';

      // Check if user already exists
      final existingUser = await db.getUser(email);

      if (existingUser == null) {
        // Create new user with Google account
        // For Google sign-in, we create a hash of "google_${email}" as password
        final googlePassword = sha256.convert(utf8.encode('google_$email')).toString();
        
        await db.createUser(
          email: email,
          password: googlePassword,
          name: displayName,
        );
        print('✅ New Google user created: $email');
      } else {
        print('✅ Existing Google user found: $email');
      }
    } catch (e) {
      print('Error handling Google Sign-In: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Google Sign-Out successful');
    } catch (e) {
      print('Sign-Out Error: $e');
      throw Exception('Sign-Out failed: $e');
    }
  }

  /// Get current user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  /// Get current user email
  Future<String?> getCurrentUserEmail() async {
    try {
      final isSignedIn = await _googleSignIn.isSignedIn();
      if (isSignedIn) {
        return _googleSignIn.currentUser?.email;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
