import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_repository.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Provider for auth state changes
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Controller for auth operations
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState()) {
    // Listen to auth state changes
    _authRepository.authStateChanges.listen((user) {
      state = state.copyWith(user: user, error: null);
    });
  }


  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Signs out the current user and updates the auth state accordingly.
  ///
  /// This method will:
  /// 1. Set loading state to true
  /// 2. Call the repository to sign out
  /// 3. Reset the user to null on success
  /// 4. Handle any errors that occur during sign out
  /// 5. Ensure loading state is always reset
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepository.signOut();
      state = state.copyWith(user: null);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message ?? 'An error occurred during sign out');
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
      rethrow;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => state.user != null;
}
