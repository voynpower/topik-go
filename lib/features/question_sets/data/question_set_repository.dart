import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';

class QuestionSetRepository {
  const QuestionSetRepository(this._dio);

  final Dio _dio;

  Future<List<QuestionSet>> getQuestionSets() async {
    final response = await _dio.get('/question-sets');
    final data = response.data;

    if (data is! List) {
      throw const FormatException('Expected question set list');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(QuestionSet.fromJson)
        .toList();
  }

  Future<QuestionSet> getQuestionSet(String id) async {
    final response = await _dio.get('/question-sets/$id');
    return QuestionSet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<QuestionSet> createQuestionSet({
    String? title,
    required String section,
    required int level,
  }) async {
    final response = await _dio.post(
      '/question-sets',
      data: {
        if (title != null && title.isNotEmpty) 'title': title,
        'section': section,
        'level': level,
      },
    );
    return QuestionSet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<QuestionSet> updateQuestionSet(
    String id, {
    String? title,
    String? section,
    int? level,
  }) async {
    final data = <String, Object>{};
    if (title != null) data['title'] = title;
    if (section != null) data['section'] = section;
    if (level != null) data['level'] = level;

    final response = await _dio.patch('/question-sets/$id', data: data);
    return QuestionSet.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteQuestionSet(String id) async {
    await _dio.delete('/question-sets/$id');
  }
}

final questionSetRepositoryProvider = Provider<QuestionSetRepository>((ref) {
  return QuestionSetRepository(ref.watch(dioProvider));
});

final questionSetsProvider = FutureProvider<List<QuestionSet>>((ref) {
  return ref.watch(questionSetRepositoryProvider).getQuestionSets();
});
