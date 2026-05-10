import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';

class PracticeSession {
  const PracticeSession({
    required this.id,
    this.questionSetId,
    this.status,
    this.currentQuestionId,
  });

  final String id;
  final String? questionSetId;
  final String? status;
  final String? currentQuestionId;

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id']?.toString() ?? '',
      questionSetId: json['question_set_id']?.toString(),
      status: json['status']?.toString(),
      currentQuestionId: json['current_question_id']?.toString(),
    );
  }
}

class PracticeAnswer {
  const PracticeAnswer({
    required this.id,
    this.questionId,
    this.selectedAnswer,
    this.textAnswer,
    this.isCorrect,
  });

  final String id;
  final String? questionId;
  final String? selectedAnswer;
  final String? textAnswer;
  final bool? isCorrect;

  factory PracticeAnswer.fromJson(Map<String, dynamic> json) {
    return PracticeAnswer(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString(),
      selectedAnswer: json['selected_answer']?.toString(),
      textAnswer: json['text_answer']?.toString(),
      isCorrect: json['is_correct'] is bool ? json['is_correct'] as bool : null,
    );
  }
}

class PracticeResult {
  const PracticeResult({
    required this.sessionId,
    required this.totalQuestions,
    required this.correctCount,
    this.score,
  });

  final String sessionId;
  final int totalQuestions;
  final int correctCount;
  final int? score;

  factory PracticeResult.fromJson(Map<String, dynamic> json) {
    return PracticeResult(
      sessionId:
          json['session_id']?.toString() ??
          json['id']?.toString() ??
          json['exam_session_id']?.toString() ??
          '',
      totalQuestions:
          _asInt(json['total_questions']) ??
          _asInt(json['total']) ??
          _asInt(json['question_count']) ??
          0,
      correctCount:
          _asInt(json['correct_count']) ??
          _asInt(json['correct']) ??
          _asInt(json['correct_answers']) ??
          0,
      score: _asInt(json['score']),
    );
  }
}

class PracticeSessionRepository {
  const PracticeSessionRepository(this._dio);

  final Dio _dio;

  Future<PracticeSession> createSession({required String questionSetId}) async {
    final response = await _dio.post(
      '/practice-sessions',
      data: {'question_set_id': questionSetId, 'mode': 'practice'},
    );
    return PracticeSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PracticeSession> getSession(String id) async {
    final response = await _dio.get('/practice-sessions/$id');
    return PracticeSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PracticeSession> updateProgress({
    required String sessionId,
    required String currentQuestionId,
  }) async {
    final response = await _dio.patch(
      '/practice-sessions/$sessionId/progress',
      data: {'current_question_id': currentQuestionId},
    );
    return PracticeSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PracticeAnswer> saveAnswer({
    required String sessionId,
    required String questionId,
    String? selectedAnswer,
    String? textAnswer,
    int? spentTimeSeconds,
  }) async {
    final response = await _dio.post(
      '/practice-sessions/$sessionId/answers',
      data: {
        'question_id': questionId,
        'selected_answer': ?selectedAnswer,
        'text_answer': ?textAnswer,
        'spent_time_seconds': ?spentTimeSeconds,
      },
    );
    return PracticeAnswer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PracticeSession> submitSession(String sessionId) async {
    final response = await _dio.post('/practice-sessions/$sessionId/submit');
    return PracticeSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PracticeResult> getResult(String sessionId) async {
    final response = await _dio.get('/practice-sessions/$sessionId/result');
    return PracticeResult.fromJson(response.data as Map<String, dynamic>);
  }
}

final practiceSessionRepositoryProvider = Provider<PracticeSessionRepository>((
  ref,
) {
  return PracticeSessionRepository(ref.watch(dioProvider));
});

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
