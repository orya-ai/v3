import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../social/domain/models/app_user.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository._(this._firebaseAuth, this._firestore);

  factory AuthRepository() {
    return AuthRepository._(FirebaseAuth.instance, FirebaseFirestore.instance);
  }

  @visibleForTesting
  AuthRepository.forTesting(FirebaseAuth firebaseAuth, FirebaseFirestore firestore)
      : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  User? get currentUser => _firebaseAuth.currentUser;

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

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        String displayName;
        if (user.email != null && user.email!.contains('@')) {
          displayName = user.email!.split('@')[0];
          if (displayName.isEmpty) {
            displayName = 'User'; 
          }
        } else if (user.email != null && user.email!.isNotEmpty) {
          displayName = user.email!;
        } else {
          displayName = 'User'; 
        }

        final appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: displayName,
          emailLowercase: (user.email ?? '').toLowerCase(),
          displayNameLowercase: displayName.toLowerCase(),
        );

        if (kDebugMode) {
            print('Attempting to save user to Firestore: ${appUser.toJson()}');
        }

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(appUser.toJson());
        
        if (kDebugMode) {
            print('User successfully saved to Firestore with UID: ${user.uid}');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('An unexpected error occurred during sign up or Firestore save: $e');
      }
      rethrow; 
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (kDebugMode) debugPrint('User signed out successfully');
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Error signing out: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) debugPrint('Unexpected error during sign out: $e');
      rethrow;
    }
  }

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

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
