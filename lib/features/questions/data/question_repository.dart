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
      'level': ?level,
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

  /// Fetches all pages for a practice set so TOPIK II reading/listening can
  /// show the full 50-question set even when the server paginates responses.
  Future<QuestionPage> getAllQuestionsForPracticeSet({
    required String section,
    String? setId,
    int? level,
    int pageSize = 30,
    int maxItems = 50,
  }) async {
    final merged = <Question>[];
    var page = 1;

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

      if (chunk.items.isEmpty) {
        if (merged.isEmpty && (setId != null || level != null)) {
          // If a selected set has no matching rows for the grade, keep the
          // grade filter when looking for section-level data.
          if (setId != null && level != null) {
            final levelFallbackChunk = await getQuestions(
              QuestionQuery(
                section: section,
                level: level,
                page: page,
                limit: pageSize,
              ),
            );
            if (levelFallbackChunk.items.isNotEmpty) {
              merged.addAll(levelFallbackChunk.items);
            }
          }
        }
        if (merged.isEmpty && setId != null && level == null) {
          final fallbackChunk = await getQuestions(
            QuestionQuery(section: section, page: page, limit: pageSize),
          );
          if (fallbackChunk.items.isNotEmpty) {
            merged.addAll(fallbackChunk.items);
          }
        }
        break;
      }

      merged.addAll(chunk.items);

      if (chunk.items.length < pageSize || merged.length >= maxItems) {
        break;
      }

      page++;
      if (page > 10) break;
    }

    // Keep the practice set in exam order (문항 번호 오름차순) instead of a
    // shuffled mix so learners solve question 1 → 2 → 3 ... in sequence.
    final ordered = orderedByExamSequence(merged);
    if (ordered.length > maxItems) {
      ordered.removeRange(maxItems, ordered.length);
    }

    return QuestionPage(
      items: ordered,
      page: 1,
      limit: ordered.length,
      total: ordered.length,
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

/// Orders practice questions by exam sequence: questions are grouped by their
/// question set (in first-seen order) and sorted by `questionNumber` inside each
/// group. Questions without a known number keep the server order and are pushed
/// to the end of their group.
List<Question> orderedByExamSequence(List<Question> questions) {
  if (questions.length < 2) return List<Question>.of(questions);

  final setOrder = <String, int>{};
  for (final question in questions) {
    setOrder.putIfAbsent(question.setId ?? '', () => setOrder.length);
  }

  final indexed = <({int index, Question question})>[
    for (var index = 0; index < questions.length; index++)
      (index: index, question: questions[index]),
  ];

  indexed.sort((a, b) {
    final groupA = setOrder[a.question.setId ?? ''] ?? 0;
    final groupB = setOrder[b.question.setId ?? ''] ?? 0;
    if (groupA != groupB) return groupA.compareTo(groupB);

    final numberA = _sequenceNumber(a.question);
    final numberB = _sequenceNumber(b.question);
    if (numberA != numberB) return numberA.compareTo(numberB);

    return a.index.compareTo(b.index);
  });

  return [for (final entry in indexed) entry.question];
}

const _unknownSequenceNumber = 1 << 30;

int _sequenceNumber(Question question) => question.questionNumber > 0
    ? question.questionNumber
    : _unknownSequenceNumber;

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
    FutureProvider.family<QuestionPage, PracticeSetQuestionsKey>((ref, key) {
      return ref
          .watch(questionRepositoryProvider)
          .getAllQuestionsForPracticeSet(
            section: key.section,
            setId: key.setId,
            level: key.level,
          );
    });

final questionProvider = FutureProvider.family<Question, String>((ref, id) {
  return ref.watch(questionRepositoryProvider).getQuestion(id);
});
