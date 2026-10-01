import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class AiExampleSentence {
  const AiExampleSentence({
    required this.korean,
    required this.translation,
    this.contextTag = '실전 예문',
  });

  final String korean;
  final String translation;
  final String contextTag;
}

/// 단어별 AI 예문 및 다국어 번역 생성 서비스 (Google Gemini 연동 + 서버 Redis 캐시 + 오프라인 폴백)
class AiSentenceService {
  // 메모리 캐시: "word-targetLang" -> List<AiExampleSentence>
  static final Map<String, List<AiExampleSentence>> _cache = {};

  static const List<String> _contextTags = [
    '일상 대화',
    'TOPIK 실전',
    '사회·문화',
    '개인 경험',
    '학술·시사',
  ];

  static void _saveToCache(String cacheKey, int index, AiExampleSentence sentence) {
    _cache.putIfAbsent(cacheKey, () => []);
    final list = _cache[cacheKey]!;
    while (list.length <= index) {
      list.add(sentence);
    }
    list[index] = sentence;
  }

  /// 단어와 인덱스에 맞는 실제 AI 예문과 모국어 번역을 가져옵니다.
  static Future<AiExampleSentence> getExample({
    required String word,
    required int index,
    required String targetLang,
    String? predefinedExample,
    String? predefinedMeaning,
    VocabularyRepository? repository,
  }) async {
    final cacheKey = '$word-$targetLang';
    final cachedList = _cache[cacheKey];

    if (cachedList != null && cachedList.length > index) {
      return cachedList[index];
    }

    final tag = _contextTags[index % _contextTags.length];

    // 1. 서버 API를 통해 실제 Gemini AI 기반 예문 요청
    if (repository != null) {
      try {
        final res = await repository.getAiExampleSentence(
          word: word,
          meaning: predefinedMeaning,
          targetLang: targetLang,
          index: index,
        );

        final korean = res['korean']?.toString().trim();
        final translation = res['translation']?.toString().trim();
        final serverContextTag = res['contextTag']?.toString().trim();

        if (korean != null && korean.isNotEmpty) {
          final aiSentence = AiExampleSentence(
            korean: korean,
            translation: (translation != null && translation.isNotEmpty)
                ? TranslationService.unescapeHtml(translation)
                : korean,
            contextTag: (serverContextTag != null && serverContextTag.isNotEmpty)
                ? serverContextTag
                : tag,
          );

          _saveToCache(cacheKey, index, aiSentence);
          return aiSentence;
        }
      } catch (_) {
        // 서버 연결 실패 또는 오프라인 시 아래 폴백으로 자연스럽게 전환
      }
    }

    // 2. 오프라인 또는 단독 테스트 환경을 위한 지능형 폴백
    String selectedKorean = '';
    if (predefinedExample != null && predefinedExample.trim().isNotEmpty && index == 0) {
      selectedKorean = predefinedExample.trim();
    } else {
      final fallbackPatterns = [
        // 0. 일상 대화
        '평소에 $word에 관심을 가지고 꾸준히 연습하고 있어요.',
        // 1. TOPIK 실전
        '전문가들은 이번 조사 결과를 통해 $word의 중요성을 다시 한번 강조했습니다.',
        // 2. 사회·문화
        '최근 우리 사회에서는 $word와 관련된 다양한 논의가 활발하게 이루어지고 있습니다.',
        // 3. 개인 경험
        '처음에는 $word에 익숙하지 않았지만, 점차 깊이 이해하게 되었습니다.',
        // 4. 학술·시사
        '학자들은 앞으로 $word에 대한 체계적인 연구가 더욱 필요하다고 밝혔습니다.',
      ];
      selectedKorean = fallbackPatterns[index % fallbackPatterns.length];
    }

    String translation = '';
    if (targetLang == 'ko') {
      translation = predefinedMeaning ?? '한국어 예문입니다.';
    } else {
      final translated = await TranslationService.translate(
        text: selectedKorean,
        targetLang: targetLang,
      );
      translation = translated ?? predefinedMeaning ?? selectedKorean;
    }

    final fallbackSentence = AiExampleSentence(
      korean: selectedKorean,
      translation: TranslationService.unescapeHtml(translation),
      contextTag: tag,
    );

    _saveToCache(cacheKey, index, fallbackSentence);
    return fallbackSentence;
  }
}

final aiSentenceProvider = FutureProvider.family<AiExampleSentence, ({
  String word,
  int index,
  String targetLang,
  String? predefinedExample,
  String? predefinedMeaning,
})>((ref, param) async {
  final repository = ref.watch(vocabularyRepositoryProvider);
  return AiSentenceService.getExample(
    word: param.word,
    index: param.index,
    targetLang: param.targetLang,
    predefinedExample: param.predefinedExample,
    predefinedMeaning: param.predefinedMeaning,
    repository: repository,
  );
});
