import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:orya/features/dashboard/data/prompts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DailyConnectionPromptService {
  static const _lastPromptDateKey = 'last_prompt_date';
  static const _lastCategoryIndexKey = 'last_category_index';
  static const _usedPromptsKeyPrefix = 'used_prompts_';

  Future<Map<String, String>> getTodaysPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final lastPromptDate = prefs.getString(_lastPromptDateKey);

    if (lastPromptDate == today) {
      // Same day, return the stored prompt
      return {
        'category': prefs.getString('today_category') ?? '',
        'prompt': prefs.getString('today_prompt') ?? ''
      };
    } else {
      // New day, get a new prompt
      final lastCategoryIndex = prefs.getInt(_lastCategoryIndexKey) ?? -1;
      final categories = dailyPrompts.keys.toList();
      final newCategoryIndex = (lastCategoryIndex + 1) % categories.length;
      final newCategory = categories[newCategoryIndex];
      final promptsForCategory = dailyPrompts[newCategory]!;

      // Get used prompts for the current category
      final usedPromptsKey = '$_usedPromptsKeyPrefix$newCategory';
      List<String> usedPromptsIndexes = prefs.getStringList(usedPromptsKey) ?? [];

      // Filter out used prompts
      List<int> availablePromptIndexes = List.generate(promptsForCategory.length, (i) => i)
          .where((i) => !usedPromptsIndexes.contains(i.toString()))
          .toList();

      // If all prompts have been used, reset the list
      if (availablePromptIndexes.isEmpty) {
        usedPromptsIndexes = [];
        await prefs.setStringList(usedPromptsKey, usedPromptsIndexes);
        availablePromptIndexes = List.generate(promptsForCategory.length, (i) => i);
      }

      // Select a random prompt from the available ones
      final randomIndex = availablePromptIndexes[Random().nextInt(availablePromptIndexes.length)];
      final newPrompt = promptsForCategory[randomIndex];

      // Add the used prompt index to the list and save it
      usedPromptsIndexes.add(randomIndex.toString());
      await prefs.setStringList(usedPromptsKey, usedPromptsIndexes);

      // Store the new prompt details for today
      await prefs.setString(_lastPromptDateKey, today);
      await prefs.setInt(_lastCategoryIndexKey, newCategoryIndex);
      await prefs.setString('today_category', newCategory);
      await prefs.setString('today_prompt', newPrompt);

      return {'category': newCategory, 'prompt': newPrompt};
    }
  }
}
