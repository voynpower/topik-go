import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockExamHistoryItem {
  const MockExamHistoryItem({
    required this.id,
    required this.title,
    required this.round,
    required this.startedAt,
    required this.endedAt,
    required this.isAutoSubmit,
    required this.sections,
    this.scorePercent,
    this.correctCount,
    this.totalQuestions,
  });

  final String id;
  final String title;
  final String round; // '83' or '102'
  final DateTime startedAt;
  final DateTime endedAt;
  final bool isAutoSubmit;
  final List<String> sections; // e.g. ['L', 'R', 'W']
  final int? scorePercent;
  final int? correctCount;
  final int? totalQuestions;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'round': round,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'is_auto_submit': isAutoSubmit,
        'sections': sections,
        'score_percent': scorePercent,
        'correct_count': correctCount,
        'total_questions': totalQuestions,
      };

  factory MockExamHistoryItem.fromJson(Map<String, dynamic> json) {
    return MockExamHistoryItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'TOPIK II',
      round: json['round']?.toString() ?? '83',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.now(),
      endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? '') ??
          DateTime.now(),
      isAutoSubmit: json['is_auto_submit'] == true,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['L', 'R', 'W'],
      scorePercent: (json['score_percent'] as num?)?.toInt(),
      correctCount: (json['correct_count'] as num?)?.toInt(),
      totalQuestions: (json['total_questions'] as num?)?.toInt(),
    );
  }
}

class MockExamHistoryRepository {
  static const _historyKey = 'mock_exam_history_items_v1';

  Future<List<MockExamHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(MockExamHistoryItem.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveAttempt(MockExamHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getHistory();
    // Prepend latest attempt
    final updated = [
      item,
      ...items.where((i) => i.id != item.id),
    ];
    await prefs.setString(
      _historyKey,
      jsonEncode(updated.map((i) => i.toJson()).toList()),
    );
  }

  Future<void> deleteAttempt(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getHistory();
    final updated = items.where((i) => i.id != id).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(updated.map((i) => i.toJson()).toList()),
    );
  }
}

final mockExamHistoryRepositoryProvider =
    Provider<MockExamHistoryRepository>((ref) {
  return MockExamHistoryRepository();
});

final mockExamHistoryListProvider =
    FutureProvider.autoDispose<List<MockExamHistoryItem>>((ref) async {
  final repo = ref.watch(mockExamHistoryRepositoryProvider);
  return repo.getHistory();
});

