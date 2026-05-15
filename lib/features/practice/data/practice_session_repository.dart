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
    final rawIsCorrect = json['is_correct'];
    return PracticeAnswer(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString(),
      selectedAnswer: json['selected_answer']?.toString(),
      textAnswer: json['text_answer']?.toString(),
      isCorrect: rawIsCorrect is bool
          ? rawIsCorrect
          : _asInt(rawIsCorrect) == null
          ? null
          : _asInt(rawIsCorrect) == 1,
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
    final session = json['session'];
    final summary = json['summary'];
    final source = summary is Map<String, dynamic> ? summary : json;
    final sessionId = session is Map<String, dynamic>
        ? session['id']?.toString()
        : null;

    return PracticeResult(
      sessionId:
          sessionId ??
          json['session_id']?.toString() ??
          json['id']?.toString() ??
          json['exam_session_id']?.toString() ??
          '',
      totalQuestions:
          _asInt(source['total_questions']) ??
          _asInt(source['total']) ??
          _asInt(source['question_count']) ??
          0,
      correctCount:
          _asInt(source['correct_count']) ??
          _asInt(source['correct']) ??
          _asInt(source['correct_answers']) ??
          0,
      score: _asInt(source['score']) ?? _asInt(source['score_percent']),
    );
  }
}

class PracticeSessionRepository {
  const PracticeSessionRepository(this._dio);

  final Dio _dio;

  Future<PracticeSession> createSession({
    required String questionSetId,
    required String section,
    int? level,
  }) async {
    final response = await _dio.post(
      '/practice-sessions',
      data: {
        'set_id': questionSetId,
        'section': section,
        'mode': 'practice',
        if (level != null) 'level': level,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final session = data['session'];
    return PracticeSession.fromJson(
      session is Map<String, dynamic> ? session : data,
    );
  }

  Future<PracticeSession> getSession(String id) async {
    final response = await _dio.get('/practice-sessions/$id');
    return PracticeSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PracticeSession> updateProgress({
    required String sessionId,
    int? currentIndex,
    int? remainingSeconds,
  }) async {
    final response = await _dio.patch(
      '/practice-sessions/$sessionId/progress',
      data: {
        if (currentIndex != null) 'current_index': currentIndex,
        if (remainingSeconds != null) 'remaining_seconds': remainingSeconds,
      },
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
        if (selectedAnswer != null) 'selected_answer': selectedAnswer,
        if (textAnswer != null) 'text_answer': textAnswer,
        if (spentTimeSeconds != null) 'spent_seconds': spentTimeSeconds,
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
