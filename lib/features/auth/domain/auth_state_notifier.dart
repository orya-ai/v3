import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

/// Enum representing different authentication states
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

/// Immutable state class for authentication
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.authenticating;
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  String toString() => 'AuthState(status: $status, user: ${user?.email}, error: $errorMessage, initialized: $isInitialized)';
}

/// StateNotifier to manage authentication state
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthStateNotifier(this._authRepository) : super(const AuthState()) {
    _initialize();
  }

  /// Initialize the auth state and listen for changes
  void _initialize() async {
    // Listen to Firebase auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (User? user) {
        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            errorMessage: null,
            isInitialized: true,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            isInitialized: true,
          );
        }
      },
      onError: (error) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString(),
          isInitialized: true,
        );
      },
    );
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // State will be updated by the auth state listener
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
      await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      // State will be updated by the auth state listener
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
      await _authRepository.signOut();
      // State will be updated by the auth state listener
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

// Provider for AuthRepository with proper dependency injection
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Provider for the auth state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository);
});

// Provider that exposes just the authentication status for components that only need that
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authStateProvider).status;
});

// Provider that exposes just the current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});
