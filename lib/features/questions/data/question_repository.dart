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
    final items = json['items'];

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

  Future<Question> getQuestion(String id) async {
    final response = await _dio.get('/questions/$id');
    return Question.fromJson(response.data as Map<String, dynamic>);
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

final questionProvider = FutureProvider.family<Question, String>((ref, id) {
  return ref.watch(questionRepositoryProvider).getQuestion(id);
});
