import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/core/theme/app_theme.dart';
import 'package:orya/features/dashboard/application/gamification_repository.dart';
import 'package:orya/features/dashboard/domain/quest_model.dart';

class QuestsPage extends ConsumerWidget {
  const QuestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsyncValue = ref.watch(questsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Quests'),
      ),
      body: questsAsyncValue.when(
        data: (quests) {
          if (quests.isEmpty) {
            return const Center(
              child: Text('You have no completed quests yet.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildQuestCard(context, ref, quest),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildQuestCard(BuildContext context, WidgetRef ref, Quest quest) {
    return Dismissible(
      key: Key(quest.title),
      onDismissed: (direction) {
        // Here you could add logic to delete the quest if needed
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${quest.title} dismissed')));
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(quest.title,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Row(
              children: [
                Text(quest.points,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(width: 5),
                const Icon(Icons.star, color: Colors.orange, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
