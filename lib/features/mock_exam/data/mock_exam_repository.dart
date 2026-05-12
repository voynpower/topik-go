import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';

class MockExamSession {
  const MockExamSession({
    required this.id,
    required this.setId,
    required this.status,
    required this.currentIndex,
    required this.remainingSeconds,
    required this.totalQuestions,
  });

  final String id;
  final String? setId;
  final String status;
  final int currentIndex;
  final int remainingSeconds;
  final int totalQuestions;

  factory MockExamSession.fromJson(Map<String, dynamic> json) {
    return MockExamSession(
      id: json['id']?.toString() ?? '',
      setId: json['set_id']?.toString(),
      status: json['status']?.toString() ?? '',
      currentIndex: _asInt(json['current_index']) ?? 0,
      remainingSeconds: _asInt(json['remaining_seconds']) ?? 0,
      totalQuestions: _asInt(json['total_questions']) ?? 0,
    );
  }
}

class MockExamAnswer {
  const MockExamAnswer({
    required this.id,
    required this.questionId,
    this.selectedAnswer,
    this.textAnswer,
    this.isCorrect,
  });

  final String id;
  final String questionId;
  final String? selectedAnswer;
  final String? textAnswer;
  final int? isCorrect;

  factory MockExamAnswer.fromJson(Map<String, dynamic> json) {
    return MockExamAnswer(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      selectedAnswer: json['selected_answer']?.toString(),
      textAnswer: json['text_answer']?.toString(),
      isCorrect: _asInt(json['is_correct']),
    );
  }
}

class MockExamDetail {
  const MockExamDetail({
    required this.session,
    required this.questions,
    required this.answers,
  });

  final MockExamSession session;
  final List<Question> questions;
  final List<MockExamAnswer> answers;

  factory MockExamDetail.fromJson(Map<String, dynamic> json) {
    final session = json['session'];
    final questions = json['questions'];
    final answers = json['answers'];

    return MockExamDetail(
      session: MockExamSession.fromJson(
        session is Map<String, dynamic> ? session : const {},
      ),
      questions: questions is List
          ? questions
                .whereType<Map<String, dynamic>>()
                .map(Question.fromJson)
                .toList()
          : const [],
      answers: answers is List
          ? answers
                .whereType<Map<String, dynamic>>()
                .map(MockExamAnswer.fromJson)
                .toList()
          : const [],
    );
  }
}

class MockExamSummary {
  const MockExamSummary({
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.scorePercent,
  });

  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final int incorrectCount;
  final int scorePercent;

  factory MockExamSummary.fromJson(Map<String, dynamic> json) {
    return MockExamSummary(
      totalQuestions: _asInt(json['total_questions']) ?? 0,
      answeredCount: _asInt(json['answered_count']) ?? 0,
      correctCount: _asInt(json['correct_count']) ?? 0,
      incorrectCount: _asInt(json['incorrect_count']) ?? 0,
      scorePercent: _asInt(json['score_percent']) ?? 0,
    );
  }
}

class MockExamResult {
  const MockExamResult({
    required this.session,
    required this.summary,
    required this.answers,
  });

  final MockExamSession session;
  final MockExamSummary summary;
  final List<MockExamAnswer> answers;

  factory MockExamResult.fromJson(Map<String, dynamic> json) {
    final session = json['session'];
    final summary = json['summary'];
    final answers = json['answers'];

    return MockExamResult(
      session: MockExamSession.fromJson(
        session is Map<String, dynamic> ? session : const {},
      ),
      summary: MockExamSummary.fromJson(
        summary is Map<String, dynamic> ? summary : const {},
      ),
      answers: answers is List
          ? answers
                .whereType<Map<String, dynamic>>()
                .map(MockExamAnswer.fromJson)
                .toList()
          : const [],
    );
  }
}

class MockExamRepository {
  const MockExamRepository(this._dio);

  final Dio _dio;

  Future<MockExamDetail> createSession({
    required String setId,
    int remainingSeconds = 4200,
  }) async {
    final response = await _dio.post(
      '/mock-exams/sessions',
      data: {'set_id': setId, 'remaining_seconds': remainingSeconds},
    );
    return MockExamDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MockExamDetail?> getActiveSession() async {
    final response = await _dio.get('/mock-exams/sessions/active');
    if (response.data == null) return null;
    return MockExamDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MockExamDetail> getSession(String id) async {
    final response = await _dio.get('/mock-exams/sessions/$id');
    return MockExamDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MockExamSession> updateProgress({
    required String sessionId,
    required int currentIndex,
    required int remainingSeconds,
  }) async {
    final response = await _dio.patch(
      '/mock-exams/sessions/$sessionId/progress',
      data: {
        'current_index': currentIndex,
        'remaining_seconds': remainingSeconds,
      },
    );
    return MockExamSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MockExamAnswer> saveAnswer({
    required String sessionId,
    required String questionId,
    String? selectedAnswer,
    String? textAnswer,
    int spentSeconds = 0,
    int bookmarked = 0,
  }) async {
    final response = await _dio.post(
      '/mock-exams/sessions/$sessionId/answers',
      data: {
        'question_id': questionId,
        'selected_answer': ?selectedAnswer,
        'text_answer': ?textAnswer,
        'spent_seconds': spentSeconds,
        'bookmarked': bookmarked,
      },
    );
    return MockExamAnswer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MockExamResult> submitSession(String sessionId) async {
    final response = await _dio.post('/mock-exams/sessions/$sessionId/submit');
    return MockExamResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MockExamResult> getResult(String sessionId) async {
    final response = await _dio.get('/mock-exams/sessions/$sessionId/result');
    return MockExamResult.fromJson(response.data as Map<String, dynamic>);
  }
}

final mockExamRepositoryProvider = Provider<MockExamRepository>((ref) {
  return MockExamRepository(ref.watch(dioProvider));
});

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
