import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'app/router/router.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ Firebase initialized successfully');
    
    // Run the app
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stack) {
    // Handle Firebase initialization errors
    print('❌ Failed to initialize Firebase: $e');
    print(stack);
    
    // Show error UI if Firebase fails to initialize
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize app. Please try again later.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Orya App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}