import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/user_vocabulary_service.dart';

enum VocabularyStudyMode {
  flashcard,
  quiz,
  dictation,
  autoplay,
}

enum StudyWordSourceType {
  saved, // 북마크에 저장된 내 단어
  all,   // 전체 TOPIK 필수 어휘
}

class StudyWordSource {
  const StudyWordSource.saved()
      : type = StudyWordSourceType.saved,
        title = '내 저장 단어장';

  const StudyWordSource.all()
      : type = StudyWordSourceType.all,
        title = '전체 TOPIK 필수 어휘';

  final StudyWordSourceType type;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyWordSource &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}

/// 한글 초성 추출 헬퍼
class HangulHelper {
  static const List<String> _initials = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  static String getInitials(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0xAC00 && rune <= 0xD7A3) {
        final initialIndex = (rune - 0xAC00) ~/ (21 * 28);
        buffer.write(_initials[initialIndex]);
      } else {
        buffer.write(String.fromCharCode(rune));
      }
    }
    return buffer.toString();
  }

  /// 공백, 문장부호 제거 후 정답 일치 검사
  static bool isSpellingMatch(String input, String target) {
    String clean(String s) =>
        s.replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '').trim().toLowerCase();
    return clean(input) == clean(target);
  }
}

/// 퀴즈 문항 모델 (4지선다)
class VocabularyQuizQuestion {
  const VocabularyQuizQuestion({
    required this.targetWord,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.isWordToMeaning,
  });

  final VocabularyItem targetWord;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final bool isWordToMeaning; // true: 단어->뜻, false: 뜻->단어

  static List<VocabularyQuizQuestion> generateQuestions(
    List<VocabularyItem> words, {
    int maxQuestions = 15,
  }) {
    if (words.isEmpty) return [];

    final random = Random();
    final shuffled = List<VocabularyItem>.from(words)..shuffle(random);
    final count = min(shuffled.length, maxQuestions);
    final questions = <VocabularyQuizQuestion>[];

    for (int i = 0; i < count; i++) {
      final target = shuffled[i];
      final isWordToMeaning = i % 2 == 0; // 교차 출제

      final prompt = isWordToMeaning ? target.word : target.meaningKo;
      final correctAnswer = isWordToMeaning ? target.meaningKo : target.word;

      // 보기 4개 추출
      final otherWords = words.where((w) => w.id != target.id).toList()..shuffle(random);
      final distractorItems = otherWords.take(3).toList();

      final optionsList = <String>[correctAnswer];
      for (final dist in distractorItems) {
        final distAnswer = isWordToMeaning ? dist.meaningKo : dist.word;
        if (!optionsList.contains(distAnswer)) {
          optionsList.add(distAnswer);
        }
      }

      // 만약 다른 단어가 3개 미만이면 더미 보기 채우기
      int dummyIdx = 1;
      while (optionsList.length < 4) {
        final dummy = isWordToMeaning ? '보기 $dummyIdx' : '단어 $dummyIdx';
        if (!optionsList.contains(dummy)) {
          optionsList.add(dummy);
        }
        dummyIdx++;
      }

      optionsList.shuffle(random);
      final correctIndex = optionsList.indexOf(correctAnswer);

      questions.add(
        VocabularyQuizQuestion(
          targetWord: target,
          prompt: prompt,
          options: optionsList,
          correctIndex: correctIndex,
          isWordToMeaning: isWordToMeaning,
        ),
      );
    }

    return questions;
  }
}

/// 학습용 단어 목록 프로바이더 (스마트 단어장의 저장 단어 기준)
final studyWordsProvider =
    FutureProvider.family<List<VocabularyItem>, StudyWordSource>((ref, source) async {
  final overrides = ref.watch(userVocabularyOverrideProvider);
  final bookmarks = await ref.watch(bookmarkRepositoryProvider).getVocabularyBookmarks();
  final words = bookmarks
      .map((b) => b.vocabulary.copyWith(isBookmarked: true))
      .toList();
  return overrides.applyOverrides(words);
});
