import 'package:topik_go/features/grammar/data/grammar_repository.dart';

enum GrammarLevelGroup {
  all,
  beginner,     // 초급 (1~2급)
  intermediate, // 중급 (3~4급)
  advanced,     // 고급 (5~6급)
  saved,        // 내 문법장
}

class ConfusingGrammarComparison {
  const ConfusingGrammarComparison({
    required this.targetPattern,
    required this.comparisonPattern,
    required this.differenceKo,
    this.differenceUz,
    this.differenceRu,
    this.differenceEn,
  });

  final String targetPattern;
  final String comparisonPattern;
  final String differenceKo;
  final String? differenceUz;
  final String? differenceRu;
  final String? differenceEn;

  String getDifference(String langCode) {
    if (langCode == 'uz' && differenceUz != null) return differenceUz!;
    if (langCode == 'ru' && differenceRu != null) return differenceRu!;
    if (langCode == 'en' && differenceEn != null) return differenceEn!;
    return differenceKo;
  }

  Map<String, dynamic> toJson() => {
    'target_pattern': targetPattern,
    'comparison_pattern': comparisonPattern,
    'difference_ko': differenceKo,
    'difference_uz': differenceUz,
    'difference_ru': differenceRu,
    'difference_en': differenceEn,
  };

  factory ConfusingGrammarComparison.fromJson(Map<String, dynamic> json) =>
      ConfusingGrammarComparison(
        targetPattern: json['target_pattern'] ?? json['targetPattern'] ?? '',
        comparisonPattern: json['comparison_pattern'] ?? json['comparisonPattern'] ?? '',
        differenceKo: json['difference_ko'] ?? json['differenceKo'] ?? '',
        differenceUz: json['difference_uz'] ?? json['differenceUz'],
        differenceRu: json['difference_ru'] ?? json['differenceRu'],
        differenceEn: json['difference_en'] ?? json['differenceEn'],
      );
}

class MasterGrammarExample {
  const MasterGrammarExample({
    required this.korean,
    this.uzbek,
    this.russian,
    this.english,
    this.tag = '일상 대화',
  });

  final String korean;
  final String? uzbek;
  final String? russian;
  final String? english;
  final String tag;

  String getTranslation(String langCode) {
    if (langCode == 'ko') return '';
    if (langCode == 'uz' && (uzbek?.isNotEmpty ?? false)) return uzbek!;
    if (langCode == 'ru' && (russian?.isNotEmpty ?? false)) return russian!;
    if (langCode == 'en' && (english?.isNotEmpty ?? false)) return english!;
    if (english?.isNotEmpty ?? false) return english!;
    return uzbek ?? russian ?? '';
  }

  Map<String, dynamic> toJson() => {
    'korean': korean,
    'uzbek': uzbek,
    'russian': russian,
    'english': english,
    'tag': tag,
  };

  factory MasterGrammarExample.fromJson(Map<String, dynamic> json) =>
      MasterGrammarExample(
        korean: json['korean'] ?? json['ko'] ?? '',
        uzbek: json['uzbek'] ?? json['uz'],
        russian: json['russian'] ?? json['ru'],
        english: json['english'] ?? json['en'],
        tag: json['tag'] ?? '일상 대화',
      );
}

class MasterGrammarQuiz {
  const MasterGrammarQuiz({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanationKo,
    this.explanationUz,
    this.explanationRu,
    this.explanationEn,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanationKo;
  final String? explanationUz;
  final String? explanationRu;
  final String? explanationEn;

  String getExplanation(String langCode) {
    if (langCode == 'uz' && explanationUz != null) return explanationUz!;
    if (langCode == 'ru' && explanationRu != null) return explanationRu!;
    if (langCode == 'en' && explanationEn != null) return explanationEn!;
    return explanationKo;
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correct_index': correctIndex,
    'explanation_ko': explanationKo,
    'explanation_uz': explanationUz,
    'explanation_ru': explanationRu,
    'explanation_en': explanationEn,
  };

  factory MasterGrammarQuiz.fromJson(Map<String, dynamic> json) =>
      MasterGrammarQuiz(
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctIndex: json['correct_index'] ?? json['correctIndex'] ?? 0,
        explanationKo: json['explanation_ko'] ?? json['explanationKo'] ?? '',
        explanationUz: json['explanation_uz'] ?? json['explanationUz'],
        explanationRu: json['explanation_ru'] ?? json['explanationRu'],
        explanationEn: json['explanation_en'] ?? json['explanationEn'],
      );
}

class MasterGrammarItem {
  const MasterGrammarItem({
    required this.id,
    required this.pattern,
    required this.level,
    required this.category,
    required this.meaningKo,
    this.meaningUz,
    this.meaningRu,
    this.meaningEn,
    required this.explanationKo,
    this.explanationUz,
    this.explanationRu,
    this.explanationEn,
    required this.conjugationRule,
    this.comparisons = const [],
    this.examples = const [],
    this.quizzes = const [],
    this.tags = const [],
  });

  final String id;
  final String pattern;
  final int level; // 1~6
  final String category; // '이유·원인', '대조·양보', '목적·의도', '조건·가정', '시간·순서', '추측·양태', '정도·강조', '변화·결과', '피동·사동', '간접화법', '기타'
  final String meaningKo;
  final String? meaningUz;
  final String? meaningRu;
  final String? meaningEn;
  final String explanationKo;
  final String? explanationUz;
  final String? explanationRu;
  final String? explanationEn;
  final String conjugationRule;
  final List<ConfusingGrammarComparison> comparisons;
  final List<MasterGrammarExample> examples;
  final List<MasterGrammarQuiz> quizzes;
  final List<String> tags;

  GrammarLevelGroup get levelGroup {
    if (level <= 2) return GrammarLevelGroup.beginner;
    if (level <= 4) return GrammarLevelGroup.intermediate;
    return GrammarLevelGroup.advanced;
  }

  String get levelLabel {
    if (level <= 2) return 'TOPIK I ($level급)';
    return 'TOPIK II ($level급)';
  }

  String getMeaning(String langCode) {
    if (langCode == 'ko' && meaningKo.isNotEmpty) return meaningKo;
    if (langCode == 'uz' && (meaningUz?.isNotEmpty ?? false)) return meaningUz!;
    if (langCode == 'ru' && (meaningRu?.isNotEmpty ?? false)) return meaningRu!;
    if (langCode == 'en' && (meaningEn?.isNotEmpty ?? false)) return meaningEn!;
    if (langCode != 'ko' && (meaningEn?.isNotEmpty ?? false)) return meaningEn!;
    return meaningKo;
  }

  String getExplanation(String langCode) {
    if (langCode == 'ko' && explanationKo.isNotEmpty) return explanationKo;
    if (langCode == 'uz' && (explanationUz?.isNotEmpty ?? false)) return explanationUz!;
    if (langCode == 'ru' && (explanationRu?.isNotEmpty ?? false)) return explanationRu!;
    if (langCode == 'en' && (explanationEn?.isNotEmpty ?? false)) return explanationEn!;
    if (langCode != 'ko' && (explanationEn?.isNotEmpty ?? false)) return explanationEn!;
    return explanationKo;
  }

  /// OneGrammar 호환 GrammarItem으로 변환
  GrammarItem toGrammarItem({bool isBookmarked = false}) {
    return GrammarItem(
      id: id,
      pattern: pattern,
      description: meaningKo,
      examples: examples.map((e) => e.korean).toList(),
      tags: [levelLabel, category, ...tags],
      isDownloaded: false,
      isBookmarked: isBookmarked,
      level: level,
      category: category,
      meaningKo: meaningKo,
      meaningUz: meaningUz,
      meaningRu: meaningRu,
      meaningEn: meaningEn,
      explanationKo: explanationKo,
      explanationUz: explanationUz,
      explanationRu: explanationRu,
      explanationEn: explanationEn,
      conjugationRule: conjugationRule,
      comparisons: comparisons,
      richExamples: examples,
      quizzes: quizzes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pattern': pattern,
    'level': level,
    'category': category,
    'description': meaningKo,
    'meaning_ko': meaningKo,
    'meaning_uz': meaningUz,
    'meaning_ru': meaningRu,
    'meaning_en': meaningEn,
    'explanation_ko': explanationKo,
    'explanation_uz': explanationUz,
    'explanation_ru': explanationRu,
    'explanation_en': explanationEn,
    'conjugation_rule': conjugationRule,
    'comparisons_json': comparisons.map((c) => c.toJson()).toList(),
    'examples_json': examples.map((e) => e.toJson()).toList(),
    'quizzes_json': quizzes.map((q) => q.toJson()).toList(),
    'tags_json': tags,
  };

  factory MasterGrammarItem.fromJson(Map<String, dynamic> json) {
    return MasterGrammarItem(
      id: json['id']?.toString() ?? '',
      pattern: json['pattern'] ?? '',
      level: json['level'] is int
          ? json['level']
          : int.tryParse(json['level']?.toString() ?? '') ?? 1,
      category: json['category'] ?? '기타',
      meaningKo: json['meaning_ko'] ?? json['description'] ?? '',
      meaningUz: json['meaning_uz'],
      meaningRu: json['meaning_ru'],
      meaningEn: json['meaning_en'],
      explanationKo: json['explanation_ko'] ?? json['description'] ?? '',
      explanationUz: json['explanation_uz'],
      explanationRu: json['explanation_ru'],
      explanationEn: json['explanation_en'],
      conjugationRule: json['conjugation_rule'] ?? '',
      comparisons: (json['comparisons_json'] as List?)
              ?.map((c) => ConfusingGrammarComparison.fromJson(Map<String, dynamic>.from(c)))
              .toList() ??
          [],
      examples: (json['examples_json'] as List?)
              ?.map((e) => MasterGrammarExample.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      quizzes: (json['quizzes_json'] as List?)
              ?.map((q) => MasterGrammarQuiz.fromJson(Map<String, dynamic>.from(q)))
              .toList() ??
          [],
      tags: (json['tags_json'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}
