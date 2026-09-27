import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/services/translation_service.dart';

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

/// 단어별 AI 예문 및 다국어 번역 생성 서비스
class AiSentenceService {
  // 메모리 캐시: word -> List<AiExampleSentence>
  static final Map<String, List<AiExampleSentence>> _cache = {};

  /// 단어에 대한 사전 탑재된 대표 예문 및 문맥 패턴 생성기
  static List<String> _getSeedExamples(String word) {
    return [
      // 1. 일상/대화 문맥
      '평소에 $word(을)를 중요하게 생각하는 편이에요.',
      // 2. TOPIK 시험/기사 문맥
      '전문가들은 이번 조사가 $word에 큰 영향을 미칠 것이라고 분석했습니다.',
      // 3. 사회/문화 문맥
      '최근 들어 $word에 대한 사람들의 관심이 점점 높아지고 있습니다.',
      // 4. 감정/경험 문맥
      '처음에는 $word이/가 낯설었지만 시간이 지나면서 점차 익숙해졌습니다.',
      // 5. 학습/성장 문맥
      '꾸준히 노력한 덕분에 $word의 의미를 깊이 이해하게 되었습니다.',
    ];
  }

  /// 단어와 인덱스에 맞는 예문과 모국어 번역을 가져옵니다.
  static Future<AiExampleSentence> getExample({
    required String word,
    required int index,
    required String targetLang,
    String? predefinedExample,
    String? predefinedMeaning,
  }) async {
    final cacheKey = '$word-$targetLang';
    final cachedList = _cache[cacheKey];

    if (cachedList != null && cachedList.length > index) {
      return cachedList[index];
    }

    // 예문 텍스트 결정
    final seeds = _getSeedExamples(word);
    if (predefinedExample != null && predefinedExample.trim().isNotEmpty) {
      // 미리 정의된 데이터베이스 예문이 있다면 1순위로 삽입
      if (!seeds.contains(predefinedExample)) {
        seeds.insert(0, predefinedExample);
      }
    }

    final selectedKorean = seeds[index % seeds.length];
    final contextTags = ['일상 대화', 'TOPIK 실전', '사회·문화', '개인 경험', '학술·시사'];
    final tag = contextTags[index % contextTags.length];

    String translation = '';
    if (targetLang == 'ko') {
      translation = predefinedMeaning ?? '한국어 예문입니다.';
    } else {
      // 다국어 자동 번역
      final translated = await TranslationService.translate(
        text: selectedKorean,
        targetLang: targetLang,
      );
      translation = translated ?? predefinedMeaning ?? selectedKorean;
    }

    final newSentence = AiExampleSentence(
      korean: selectedKorean,
      translation: translation,
      contextTag: tag,
    );

    _cache.putIfAbsent(cacheKey, () => []);
    if (_cache[cacheKey]!.length <= index) {
      _cache[cacheKey]!.add(newSentence);
    } else {
      _cache[cacheKey]![index] = newSentence;
    }

    return newSentence;
  }
}

final aiSentenceProvider = FutureProvider.family<AiExampleSentence, ({String word, int index, String targetLang, String? predefinedExample, String? predefinedMeaning})>((ref, param) async {
  return AiSentenceService.getExample(
    word: param.word,
    index: param.index,
    targetLang: param.targetLang,
    predefinedExample: param.predefinedExample,
    predefinedMeaning: param.predefinedMeaning,
  );
});
