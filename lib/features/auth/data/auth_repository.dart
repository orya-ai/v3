import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  // Private constructor
  AuthRepository._(this._firebaseAuth);

  // Factory constructor for production use
  factory AuthRepository() {
    return AuthRepository._(FirebaseAuth.instance);
  }

  // For testing with mock FirebaseAuth
  @visibleForTesting
  AuthRepository.forTesting(FirebaseAuth firebaseAuth) : _firebaseAuth = firebaseAuth;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Email & Password Sign In
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Signs out the current user from Firebase Authentication.
  /// 
  /// Throws an [AuthException] if the sign out process fails.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      debugPrint('User signed out successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('Error signing out: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during sign out: $e');
      rethrow;
    }
  }

  // Handle auth exceptions
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException('No user found with this email.');
      case 'wrong-password':
        return const AuthException('Incorrect password.');
      case 'email-already-in-use':
        return const AuthException('Email already in use.');
      case 'weak-password':
        return const AuthException('Password must be at least 6 characters.');
      case 'invalid-email':
        return const AuthException('Invalid email address.');
      case 'too-many-requests':
        return const AuthException('Too many requests. Please try again later.');
      case 'operation-not-allowed':
        return const AuthException('Email/password accounts are not enabled.');
      default:
        return AuthException(e.message ?? 'An unknown error occurred');
    }
  }
}

// Custom exception class for auth errors
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
