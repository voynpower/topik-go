import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class BookmarkSummary {
  const BookmarkSummary({
    required this.questions,
    required this.vocabulary,
    required this.grammar,
  });

  final int questions;
  final int vocabulary;
  final int grammar;

  factory BookmarkSummary.fromJson(Map<String, dynamic> json) {
    return BookmarkSummary(
      questions: _asInt(json['questions']) ?? 0,
      vocabulary: _asInt(json['vocabulary']) ?? 0,
      grammar: _asInt(json['grammar']) ?? 0,
    );
  }
}

class BookmarkedQuestion {
  const BookmarkedQuestion({
    required this.id,
    required this.question,
    this.selectedAnswer,
    this.textAnswer,
    this.isCorrect,
  });

  final String id;
  final Question question;
  final String? selectedAnswer;
  final String? textAnswer;
  final bool? isCorrect;

  factory BookmarkedQuestion.fromJson(Map<String, dynamic> json) {
    final rawQuestion = json['question'];

    return BookmarkedQuestion(
      id: json['id']?.toString() ?? '',
      question: rawQuestion is Map<String, dynamic>
          ? Question.fromJson(rawQuestion)
          : Question.fromJson(json),
      selectedAnswer: json['selected_answer']?.toString(),
      textAnswer: json['text_answer']?.toString(),
      isCorrect: json['is_correct'] is bool ? json['is_correct'] as bool : null,
    );
  }
}

class BookmarkedVocabulary {
  const BookmarkedVocabulary({required this.id, required this.vocabulary});

  final String id;
  final VocabularyItem vocabulary;

  factory BookmarkedVocabulary.fromJson(Map<String, dynamic> json) {
    final rawVocabulary = json['vocabulary'];

    return BookmarkedVocabulary(
      id: json['id']?.toString() ?? '',
      vocabulary: rawVocabulary is Map<String, dynamic>
          ? VocabularyItem.fromJson(rawVocabulary)
          : VocabularyItem.fromJson(json),
    );
  }
}

class BookmarkedGrammar {
  const BookmarkedGrammar({required this.id, required this.grammar});

  final String id;
  final GrammarItem grammar;

  factory BookmarkedGrammar.fromJson(Map<String, dynamic> json) {
    final rawGrammar = json['grammar_items'] ?? json['grammar'];

    return BookmarkedGrammar(
      id: json['id']?.toString() ?? '',
      grammar: rawGrammar is Map<String, dynamic>
          ? GrammarItem.fromJson(rawGrammar)
          : GrammarItem.fromJson(json),
    );
  }
}

class BookmarkRepository {
  const BookmarkRepository(this._dio);

  final Dio _dio;

  Future<BookmarkSummary> getSummary() async {
    final response = await _dio.get('/bookmarks/summary');
    return BookmarkSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<BookmarkedQuestion>> getQuestionBookmarks() async {
    final response = await _dio.get('/bookmarks/questions');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Expected bookmarked question list');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(BookmarkedQuestion.fromJson)
        .toList();
  }

  Future<void> setQuestionBookmark({
    required String questionId,
    required bool bookmarked,
  }) async {
    await _dio.patch(
      '/bookmarks/questions/$questionId',
      data: {'bookmarked': bookmarked},
    );
  }

  Future<List<BookmarkedVocabulary>> getVocabularyBookmarks() async {
    final items = await _getRawList('/bookmarks/vocabulary');
    return items.map(BookmarkedVocabulary.fromJson).toList();
  }

  Future<void> setVocabularyBookmark({
    required String vocabularyId,
    required bool bookmarked,
  }) async {
    await _dio.patch(
      '/bookmarks/vocabulary/$vocabularyId',
      data: {'bookmarked': bookmarked},
    );
  }

  Future<List<BookmarkedGrammar>> getGrammarBookmarks() async {
    final items = await _getRawList('/bookmarks/grammar');
    return items.map(BookmarkedGrammar.fromJson).toList();
  }

  Future<void> setGrammarBookmark({
    required String grammarId,
    required bool bookmarked,
  }) async {
    await _dio.patch(
      '/bookmarks/grammar/$grammarId',
      data: {'bookmarked': bookmarked},
    );
  }

  Future<List<Map<String, dynamic>>> _getRawList(String path) async {
    final response = await _dio.get(path);
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Expected bookmark list');
    }
    return data.whereType<Map<String, dynamic>>().toList();
  }
}

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(dioProvider));
});

final bookmarkSummaryProvider = FutureProvider<BookmarkSummary>((ref) {
  return ref.watch(bookmarkRepositoryProvider).getSummary();
});

final bookmarkedQuestionsProvider = FutureProvider<List<BookmarkedQuestion>>((
  ref,
) {
  return ref.watch(bookmarkRepositoryProvider).getQuestionBookmarks();
});

final bookmarkedQuestionIdsProvider = FutureProvider<Set<String>>((ref) async {
  final bookmarks = await ref.watch(bookmarkedQuestionsProvider.future);
  return bookmarks
      .map((item) => item.question.id)
      .where((id) => id.isNotEmpty)
      .toSet();
});

final bookmarkedVocabularyProvider = FutureProvider<List<BookmarkedVocabulary>>(
  (ref) {
    return ref.watch(bookmarkRepositoryProvider).getVocabularyBookmarks();
  },
);

final bookmarkedGrammarProvider = FutureProvider<List<BookmarkedGrammar>>((
  ref,
) {
  return ref.watch(bookmarkRepositoryProvider).getGrammarBookmarks();
});

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
