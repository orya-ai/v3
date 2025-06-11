import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/routes.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Assuming ActivitiesPage might want its own AppBar if not deeply nested
      // or if MainScaffold's AppBar is generic.
      // If MainScaffold already provides a suitable AppBar, this can be removed.
      appBar: AppBar(
        title: const Text('Activities'),
        automaticallyImplyLeading: false, // Remove back button if it's a main tab
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Activities Page', style: TextStyle(fontSize: 20)), // Removed color: Colors.white as Scaffold bg is likely white
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.conversationCards);
              },
              child: const Text('Go to Conversation Cards'),
            ),
          ],
        ),
      ),
    );
  }
}