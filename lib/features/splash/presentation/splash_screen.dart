import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/router.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Wait for auth state to be determined
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final authState = ref.read(authControllerProvider);
    
    if (authState.isAuthenticated) {
      // Redirect to home if authenticated
      if (mounted) {
        context.go('/');
      }
    } else {
      // Redirect to login if not authenticated
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
