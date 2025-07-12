import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/routes.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Activities Page', style: TextStyle(fontSize: 20)), // Removed color: Colors.white as Scaffold bg is likely white
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.push(AppRoutes.conversationCards);
            },
            child: const Text('Go to Conversation Cards'),
          ),
        ],
      ),
    );
  }
}