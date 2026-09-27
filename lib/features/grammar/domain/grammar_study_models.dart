import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';

enum GrammarStudyMode {
  flashcard,
  quiz,
}

enum GrammarSourceType {
  all,
  saved,
}

class GrammarStudySource {
  const GrammarStudySource.all()
      : type = GrammarSourceType.all,
        title = '전체 TOPIK 필수 문법';

  const GrammarStudySource.saved()
      : type = GrammarSourceType.saved,
        title = '내 저장 문법';

  final GrammarSourceType type;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrammarStudySource &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}

final studyGrammarProvider = FutureProvider.family<List<GrammarItem>, GrammarStudySource>((ref, source) async {
  if (source.type == GrammarSourceType.saved) {
    final bookmarks = await ref.watch(bookmarkedGrammarProvider.future);
    return bookmarks.map((b) => b.grammar).toList();
  } else {
    final page = await ref.watch(grammarProvider(const GrammarQuery(page: 1, limit: 100)).future);
    return page.items;
  }
});

enum GrammarCategoryType {
  all,
  reason,
  contrast,
  purpose,
  condition,
  time,
  other,
}

class GrammarCategory {
  const GrammarCategory({
    required this.type,
    required this.name,
    required this.keywords,
  });

  final GrammarCategoryType type;
  final String name;
  final List<String> keywords;

  static const List<GrammarCategory> categories = [
    GrammarCategory(
      type: GrammarCategoryType.all,
      name: '전체',
      keywords: [],
    ),
    GrammarCategory(
      type: GrammarCategoryType.reason,
      name: '이유·원인',
      keywords: [
        '이유', '원인', 'cause', 'reason', '바람에', '탓', '덕분', '아서', '어서', '니까',
        '때문', '느라고', '길래', '통에', '자니',
      ],
    ),
    GrammarCategory(
      type: GrammarCategoryType.contrast,
      name: '대조·양보',
      keywords: [
        '대조', '양보', 'contrast', 'concession', '지만', '반면에', '는데도', '아/어도',
        '더라도', '을망정', '을지라도', '건만', '는데 반해',
      ],
    ),
    GrammarCategory(
      type: GrammarCategoryType.purpose,
      name: '목적·의도',
      keywords: [
        '목적', '의도', 'purpose', 'intention', '려고', '러', '위해', '도록', '자고',
        '기 마련',
      ],
    ),
    GrammarCategory(
      type: GrammarCategoryType.condition,
      name: '조건·가정',
      keywords: [
        '조건', '가정', 'condition', 'hypothesis', '으면', '거든', '려면', '았더라면',
        '었더라면', '는 한', '는 이상',
      ],
    ),
    GrammarCategory(
      type: GrammarCategoryType.time,
      name: '시간·순서',
      keywords: [
        '시간', '순서', 'time', 'sequence', '전에', '후에', '고 나서', '는 동안', '을 때',
        '자마자', '는 길에', '기 바쁘게',
      ],
    ),
  ];

  static bool matches(GrammarItem item, GrammarCategoryType categoryType) {
    if (categoryType == GrammarCategoryType.all) return true;
    final cat = categories.firstWhere(
      (c) => c.type == categoryType,
      orElse: () => categories.first,
    );
    if (cat.keywords.isEmpty) return true;

    final targetText = '${item.pattern} ${item.description} ${item.tags.join(' ')}'.toLowerCase();
    return cat.keywords.any((kw) => targetText.contains(kw.toLowerCase()));
  }
}

/// TOPIK 실전형 문맥 빈칸 문법 퀴즈 문항 모델
class GrammarQuizQuestion {
  const GrammarQuizQuestion({
    required this.targetGrammar,
    required this.sentence,
    required this.clozeSentence,
    required this.options,
    required this.correctIndex,
    required this.matchedSnippet,
  });

  final GrammarItem targetGrammar;
  final String sentence; // 원문 예문
  final String clozeSentence; // 빈칸 (      ) 처리된 예문
  final List<String> options; // 4개 선택지 패턴
  final int correctIndex; // 정답 인덱스 (0~3)
  final String matchedSnippet; // 빈칸에 들어갈 정답 어휘/표현

  /// 문법 목록으로부터 4지선다형 문맥 퀴즈 자동 생성
  static List<GrammarQuizQuestion> generateQuestions(
    List<GrammarItem> items, {
    int maxQuestions = 10,
  }) {
    if (items.length < 2) return [];

    final random = Random();
    final candidateItems = items.where((g) => g.examples.isNotEmpty).toList();
    if (candidateItems.isEmpty) return [];

    final shuffled = List<GrammarItem>.from(candidateItems)..shuffle(random);
    final questions = <GrammarQuizQuestion>[];

    for (final grammar in shuffled) {
      if (questions.length >= maxQuestions) break;

      // 1. 대표 예문 선택
      final example = grammar.examples.first;
      // 2. 예문에서 문법 패턴 키워드 추출
      final cleanPattern = _cleanPattern(grammar.pattern);
      if (cleanPattern.isEmpty) continue;

      // 예문 내에서 매칭 찾기
      String cloze = '';
      String snippet = cleanPattern;

      // 패턴의 대표 형태가 예문에 존재하는지 검색
      final directIndex = example.indexOf(cleanPattern);
      if (directIndex >= 0) {
        snippet = example.substring(directIndex, directIndex + cleanPattern.length);
        cloze = example.replaceRange(directIndex, directIndex + cleanPattern.length, '(      )');
      } else {
        // 어근 2글자 이상으로 검색 시도
        final subSnippet = _findSubMatch(example, cleanPattern);
        if (subSnippet != null) {
          snippet = subSnippet;
          final idx = example.indexOf(subSnippet);
          cloze = example.replaceRange(idx, idx + subSnippet.length, '(      )');
        } else {
          // fallback: 예문의 중간 어절을 빈칸으로 치환
          final words = example.split(' ');
          if (words.length >= 3) {
            final targetWordIdx = words.length ~/ 2;
            snippet = words[targetWordIdx];
            words[targetWordIdx] = '(      )';
            cloze = words.join(' ');
          } else {
            continue;
          }
        }
      }

      // 3. 오답 선택지 3개 구성
      final otherPatterns = items
          .where((other) => other.id != grammar.id)
          .map((other) => other.pattern)
          .toSet()
          .toList()
        ..shuffle(random);

      if (otherPatterns.length < 3) continue;

      final options = [grammar.pattern];
      for (final p in otherPatterns) {
        if (options.length >= 4) break;
        if (!options.contains(p)) {
          options.add(p);
        }
      }

      options.shuffle(random);
      final correctIndex = options.indexOf(grammar.pattern);

      questions.add(
        GrammarQuizQuestion(
          targetGrammar: grammar,
          sentence: example,
          clozeSentence: cloze,
          options: options,
          correctIndex: correctIndex,
          matchedSnippet: snippet,
        ),
      );
    }

    return questions;
  }

  static String _cleanPattern(String pattern) {
    return pattern
        .replaceAll(RegExp(r'[\-\(\)\[\]/]', unicode: true), '')
        .trim();
  }

  static String? _findSubMatch(String example, String cleanPattern) {
    if (cleanPattern.length < 2) return null;
    for (int len = cleanPattern.length; len >= 2; len--) {
      for (int i = 0; i <= cleanPattern.length - len; i++) {
        final sub = cleanPattern.substring(i, i + len);
        if (example.contains(sub)) {
          return sub;
        }
      }
    }
    return null;
  }
}
