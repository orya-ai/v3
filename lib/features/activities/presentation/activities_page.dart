import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:orya/core/theme/app_theme.dart';
import '../../../app/router/routes.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Center(
            child: Text(
              'Activities',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.push(AppRoutes.conversationCards),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: AppTheme.primaryBackgroundColor,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Connection Cards",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Deepen your relationships with meaningful conversations.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryTextColor,
                          ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward, color: AppTheme.primaryTextColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.push(AppRoutes.truthOrDareRoulette),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: AppTheme.primaryBackgroundColor,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Truth or Dare Roulette",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Spin the wheel. Break the ice. Feel the real.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryTextColor,
                          ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward, color: AppTheme.primaryTextColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}