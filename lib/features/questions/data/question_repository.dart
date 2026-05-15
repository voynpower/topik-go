import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';

class QuestionPage {
  const QuestionPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Question> items;
  final int page;
  final int limit;
  final int total;

  factory QuestionPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] ?? json['questions'];

    return QuestionPage(
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(Question.fromJson)
                .toList()
          : const [],
      page: _asInt(json['page']) ?? 1,
      limit: _asInt(json['limit']) ?? 20,
      total: _asInt(json['total']) ?? 0,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class QuestionQuery {
  const QuestionQuery({
    this.section,
    this.level,
    this.questionType,
    this.setId,
    this.page = 1,
    this.limit = 20,
  });

  final String? section;
  final int? level;
  final String? questionType;
  final String? setId;
  final int page;
  final int limit;

  Map<String, Object> toQueryParameters() {
    return {
      if (section != null && section!.isNotEmpty) 'section': section!,
      if (level != null) 'level': level!,
      if (questionType != null && questionType!.isNotEmpty)
        'question_type': questionType!,
      if (setId != null && setId!.isNotEmpty) 'set_id': setId!,
      'page': page,
      'limit': limit,
    };
  }

  QuestionQuery copyWith({
    String? section,
    int? level,
    String? questionType,
    String? setId,
    int? page,
    int? limit,
  }) {
    return QuestionQuery(
      section: section ?? this.section,
      level: level ?? this.level,
      questionType: questionType ?? this.questionType,
      setId: setId ?? this.setId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestionQuery &&
            other.section == section &&
            other.level == level &&
            other.questionType == questionType &&
            other.setId == setId &&
            other.page == page &&
            other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(section, level, questionType, setId, page, limit);
  }
}

/// Key for loading every page of a practice set into one [QuestionPage].
class PracticeSetQuestionsKey {
  const PracticeSetQuestionsKey({
    required this.section,
    this.setId,
    this.level,
  });

  final String section;
  final String? setId;
  final int? level;

  @override
  bool operator ==(Object other) {
    return other is PracticeSetQuestionsKey &&
        other.section == section &&
        other.setId == setId &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(section, setId, level);
}

class QuestionRepository {
  const QuestionRepository(this._dio);

  final Dio _dio;

  Future<QuestionPage> getQuestions(QuestionQuery query) async {
    final response = await _dio.get(
      '/questions',
      queryParameters: query.toQueryParameters(),
    );
    return QuestionPage.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetches all pages for a set (e.g. server caps at 30 per request but total is 50).
  /// For practice, we cap it at 30 items as requested.
  Future<QuestionPage> getAllQuestionsForPracticeSet({
    required String section,
    String? setId,
    int? level,
    int pageSize = 30,
    int maxItems = 30,
  }) async {
    // If no setId AND no level, we can't fetch anything specific enough for practice.
    if ((setId == null || setId.isEmpty) && level == null) {
      return const QuestionPage(items: [], page: 1, limit: 0, total: 0);
    }

    final merged = <Question>[];
    int totalCount = 0;
    var page = 1;

    // Continue fetching until we have enough items or no more pages.
    while (merged.length < maxItems) {
      final chunk = await getQuestions(
        QuestionQuery(
          section: section,
          setId: setId,
          level: level,
          page: page,
          limit: pageSize,
        ),
      );

      if (chunk.items.isEmpty) break;

      merged.addAll(chunk.items);
      totalCount = chunk.total;

      // Stop if we got a short page (end of data) or reached maxItems
      if (chunk.items.length < pageSize || merged.length >= maxItems) {
        break;
      }

      page++;
      if (page > 10) break; // Safety break
    }

    // Strictly cap at maxItems
    if (merged.length > maxItems) {
      merged.removeRange(maxItems, merged.length);
    }

    return QuestionPage(
      items: merged,
      page: 1,
      limit: merged.length,
      total: merged.length, // Display the actual count fetched
    );
  }

  Future<Question> getQuestion(String id) async {
    final response = await _dio.get('/questions/$id');
    return Question.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markAsDownloaded(String id) async {
    await _dio.post('/questions/$id/download');
  }

  Future<void> removeDownloadMarker(String id) async {
    await _dio.delete('/questions/$id/download');
  }
}

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.watch(dioProvider));
});

final questionsProvider = FutureProvider.family<QuestionPage, QuestionQuery>((
  ref,
  query,
) {
  return ref.watch(questionRepositoryProvider).getQuestions(query);
});

final practiceQuestionsProvider =
    FutureProvider.family<QuestionPage, PracticeSetQuestionsKey>((
  ref,
  key,
) {
  return ref.watch(questionRepositoryProvider).getAllQuestionsForPracticeSet(
        section: key.section,
        setId: key.setId,
        level: key.level,
      );
});

final questionProvider = FutureProvider.family<Question, String>((ref, id) {
  return ref.watch(questionRepositoryProvider).getQuestion(id);
});
