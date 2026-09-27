import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WordMasteryStatus {
  unseen,
  hard,    // 어려워요 (🔴)
  unsure,  // 애매해요 (🟡)
  mastered // 외웠어요 (🟢)
}

class WordMasteryNotifier extends Notifier<Map<String, WordMasteryStatus>> {
  static const _prefKey = 'user_word_mastery_map';

  @override
  Map<String, WordMasteryStatus> build() {
    _loadFromPrefs();
    return {};
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_prefKey);
    if (rawJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(rawJson);
        final map = <String, WordMasteryStatus>{};
        decoded.forEach((key, value) {
          if (value == 'hard') {
            map[key] = WordMasteryStatus.hard;
          } else if (value == 'unsure') {
            map[key] = WordMasteryStatus.unsure;
          } else if (value == 'mastered') {
            map[key] = WordMasteryStatus.mastered;
          } else {
            map[key] = WordMasteryStatus.unseen;
          }
        });
        state = map;
      } catch (_) {}
    }
  }

  Future<void> setStatus(String wordId, WordMasteryStatus status) async {
    final next = Map<String, WordMasteryStatus>.from(state);
    next[wordId] = status;
    state = next;

    final prefs = await SharedPreferences.getInstance();
    final toSave = next.map((k, v) => MapEntry(k, v.name));
    await prefs.setString(_prefKey, jsonEncode(toSave));
  }

  Future<void> cycleStatus(String wordId) async {
    final current = state[wordId] ?? WordMasteryStatus.hard;
    WordMasteryStatus next;
    switch (current) {
      case WordMasteryStatus.unseen:
      case WordMasteryStatus.hard:
        next = WordMasteryStatus.unsure;
        break;
      case WordMasteryStatus.unsure:
        next = WordMasteryStatus.mastered;
        break;
      case WordMasteryStatus.mastered:
        next = WordMasteryStatus.hard;
        break;
    }
    await setStatus(wordId, next);
  }

  WordMasteryStatus getStatus(String wordId) {
    return state[wordId] ?? WordMasteryStatus.hard; // 기본값은 어려워요
  }
}

final wordMasteryProvider = NotifierProvider<WordMasteryNotifier, Map<String, WordMasteryStatus>>(() {
  return WordMasteryNotifier();
});
