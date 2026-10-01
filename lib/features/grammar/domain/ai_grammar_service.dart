import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/services/translation_service.dart';

class AiGrammarExample {
  const AiGrammarExample({
    required this.korean,
    required this.translation,
    this.tag = 'TOPIK 실전',
  });

  final String korean;
  final String translation;
  final String tag;

  Map<String, dynamic> toJson() => {
        'korean': korean,
        'translation': translation,
        'tag': tag,
      };

  factory AiGrammarExample.fromJson(Map<String, dynamic> json) =>
      AiGrammarExample(
        korean: json['korean']?.toString() ?? '',
        translation: json['translation']?.toString() ?? '',
        tag: json['tag']?.toString() ?? 'TOPIK 실전',
      );
}

class AiGrammarDetail {
  const AiGrammarDetail({
    required this.id,
    required this.pattern,
    required this.category,
    required this.level,
    required this.meaning,
    required this.explanation,
    required this.conjugationRule,
    required this.examples,
    this.contextSentence,
    this.targetLang = 'ko',
    this.isBookmarked = false,
  });

  final String id;
  final String pattern;
  final String category;
  final int level;
  final String meaning;
  final String explanation;
  final String conjugationRule;
  final List<AiGrammarExample> examples;
  final String? contextSentence;
  final String targetLang;
  final bool isBookmarked;

  AiGrammarDetail copyWith({
    String? id,
    String? pattern,
    String? category,
    int? level,
    String? meaning,
    String? explanation,
    String? conjugationRule,
    List<AiGrammarExample>? examples,
    String? contextSentence,
    String? targetLang,
    bool? isBookmarked,
  }) {
    return AiGrammarDetail(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      category: category ?? this.category,
      level: level ?? this.level,
      meaning: meaning ?? this.meaning,
      explanation: explanation ?? this.explanation,
      conjugationRule: conjugationRule ?? this.conjugationRule,
      examples: examples ?? this.examples,
      contextSentence: contextSentence ?? this.contextSentence,
      targetLang: targetLang ?? this.targetLang,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pattern': pattern,
        'category': category,
        'level': level,
        'meaning': meaning,
        'explanation': explanation,
        'conjugation_rule': conjugationRule,
        'examples': examples.map((e) => e.toJson()).toList(),
        'context_sentence': contextSentence,
        'target_lang': targetLang,
        'is_bookmarked': isBookmarked,
      };

  factory AiGrammarDetail.fromJson(Map<String, dynamic> json) {
    final rawExamples = json['examples'];
    final examplesList = rawExamples is List
        ? rawExamples
            .whereType<Map<String, dynamic>>()
            .map(AiGrammarExample.fromJson)
            .toList()
        : <AiGrammarExample>[];

    return AiGrammarDetail(
      id: json['id']?.toString() ?? '',
      pattern: json['pattern']?.toString() ?? '',
      category: json['category']?.toString() ?? '기타',
      level: (json['level'] as num?)?.toInt() ?? 3,
      meaning: json['meaning']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      conjugationRule: json['conjugation_rule']?.toString() ?? '',
      examples: examplesList,
      contextSentence: json['context_sentence']?.toString(),
      targetLang: json['target_lang']?.toString() ?? 'ko',
      isBookmarked: json['is_bookmarked'] == true || json['is_bookmarked'] == 1,
    );
  }
}

class _SeedGrammar {
  const _SeedGrammar({
    required this.pattern,
    required this.category,
    required this.level,
    required this.meaningKo,
    required this.explanationKo,
    required this.ruleKo,
    required this.examplesKo,
    this.uzbekMeaning,
    this.uzbekExplanation,
    this.russianMeaning,
    this.russianExplanation,
    this.englishMeaning,
    this.englishExplanation,
  });

  final String pattern;
  final String category;
  final int level;
  final String meaningKo;
  final String explanationKo;
  final String ruleKo;
  final List<String> examplesKo;

  final String? uzbekMeaning;
  final String? uzbekExplanation;
  final String? russianMeaning;
  final String? russianExplanation;
  final String? englishMeaning;
  final String? englishExplanation;
}

class AiGrammarService {
  static final Map<String, AiGrammarDetail> _cache = {};

  static const List<_SeedGrammar> _seedGrammars = [
    _SeedGrammar(
      pattern: '-는 바람에',
      category: '이유·원인',
      level: 3,
      meaningKo: '예상치 못한 일로 부정적인 결과를 초래함',
      explanationKo: '어떤 일의 부정적이거나 불만족스러운 원인을 나타내며, 뒤 절에는 청유형(-ㅂ시다)이나 명령형(-으십시오)을 쓸 수 없습니다.',
      ruleKo: '동사 어간 + 는 바람에 (과거형 결합 불가, 받침 무관)',
      examplesKo: [
        '비가 갑자기 오는 바람에 옷이 다 젖었어요.',
        '출근길에 사고가 나는 바람에 회의에 늦었습니다.',
        '감기에 심하게 걸리는 바람에 시험을 제대로 못 봤어요.',
      ],
      uzbekMeaning: 'Kutilmagan salbiy oqibatning sababini bildirish',
      uzbekExplanation: 'Biror kutilmagan holat sababli yomon/salbiy natija yuz berganda ishlatiladi. Orqa gapda buyruq yoki taklif shakli kelishi mumkin emas.',
      russianMeaning: 'Из-за неожиданного негативного обстоятельства',
      russianExplanation: 'Указывает на непредвиденную причину отрицательного последствия. В главной части нельзя использовать повелительное или пригласительное наклонение.',
      englishMeaning: 'Because of / As a negative consequence of',
      englishExplanation: 'Used when an unexpected event causes an undesirable or negative result. Cannot be used with commands or suggestions.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄹ 뿐만 아니라',
      category: '대조·양보',
      level: 3,
      meaningKo: '앞선 사실에 더하여 다른 사실도 그러함을 나타냄 (뿐만 아니라)',
      explanationKo: '앞 문장의 사실에 더해 다른 좋은 점이나 나쁜 점이 덧붙여질 때 사용하며, 긍정적인 내용 뒤에는 긍정, 부정적인 내용 뒤에는 부정이 이어집니다.',
      ruleKo: '동사/형용사 어간 + -(으)ㄹ 뿐만 아니라 (받침 O: -을, 받침 X/ㄹ: -ㄹ), 명사 + 일 뿐만 아니라',
      examplesKo: [
        '이 식당은 음식이 맛있을 뿐만 아니라 가격도 저렴해요.',
        '그 사람은 한국어를 유창하게 할 뿐만 아니라 영어도 잘합니다.',
        '태풍 때문에 바람이 심하게 불 뿐만 아니라 비도 쏟아지고 있어요.',
      ],
      uzbekMeaning: 'Nafaqat ..., balki ... ham (qo‘shimcha holat)',
      uzbekExplanation: 'Oldingi faktga qo‘shimcha ravishda boshqa bir yaxshi yoki yomon holat ham mavjudligini bildiradi.',
      russianMeaning: 'Не только ..., но и ...',
      russianExplanation: 'Выражает добавление одного факта к другому. Если первая часть положительная, вторая тоже должна быть положительной.',
      englishMeaning: 'Not only ..., but also ...',
      englishExplanation: 'Used to state that in addition to the preceding fact, another fact also applies.',
    ),
    _SeedGrammar(
      pattern: '-느라고',
      category: '이유·원인',
      level: 3,
      meaningKo: '앞선 행동을 하느라 뒤의 일을 못하거나 부정적인 결과가 됨',
      explanationKo: '앞의 행동에 시간과 노력이 집중되어 뒤의 다른 행동을 하지 못했을 때 쓰는 이유 표현입니다. 주어가 앞뒤 절에서 같아야 합니다.',
      ruleKo: '동사 어간 + 느라고 (형용사 결합 불가)',
      examplesKo: [
        '어제 밤늦게까지 시험공부를 하느라고 잠을 못 잤어요.',
        '친구와 통화를 하느라고 지하철 환승역을 지나쳤습니다.',
        '요즘 이사를 준비하느라고 정신없이 바빠요.',
      ],
      uzbekMeaning: '... qilish bilan ovora bo‘lib (salbiy natija)',
      uzbekExplanation: 'Biror harakatga vaqt va kuch sarflab boshqa ishni bajara olmaganlik sababini bildiradi. Har ikki gapda ega bir xil bo‘lishi shart.',
      russianMeaning: 'Из-за того, что был занят (делая что-то)',
      russianExplanation: 'Указывает на действие, отнявшее время и силы, из-за чего возник отрицательный результат. Подлежащее обеих частей должно совпадать.',
      englishMeaning: 'Because of / As a result of spending time doing',
      englishExplanation: 'Expresses that doing one action caused an undesirable outcome or prevented another action from happening.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄴ/는 대신에',
      category: '대조·양보',
      level: 3,
      meaningKo: '앞의 일 대신 다른 것으로 대체하거나 상반되는 대가를 치름',
      explanationKo: '어떤 행동이나 사물을 다른 것으로 바꿀 때, 혹은 어떤 장점이 있는 반면 상반되는 단점이 있음을 나타냅니다.',
      ruleKo: '동사: -는 대신에 (과거 -(으)ㄴ 대신에), 형용사: -(으)ㄴ 대신에, 명사: 대신에',
      examplesKo: [
        '제가 설거지를 하는 대신에 요리는 네가 해 줘.',
        '이 집은 역에서 가까운 대신에 집세가 비싼 편이에요.',
        '주말에 쉰 대신에 월요일에 야근을 해야 합니다.',
      ],
      uzbekMeaning: 'O‘rniga / Buning evaziga',
      uzbekExplanation: 'Biror ish o‘rniga boshqa ishni bajarish yoki biror afzallik evaziga kamchilik mavjudligini bildiradi.',
      russianMeaning: 'Вместо того чтобы... / Взамен',
      russianExplanation: 'Указывает на замену одного действия другим или компенсацию одного свойства противоположным.',
      englishMeaning: 'Instead of / In return for / On the other hand',
      englishExplanation: 'Expresses substituting one thing for another, or compensating for a feature with an opposing one.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄴ/는 반면에',
      category: '대조·양보',
      level: 3,
      meaningKo: '두 가지 사실이 상반되거나 대조적임을 나타냄',
      explanationKo: '앞 절의 긍정적인 면과 뒤 절의 부정적인 면(또는 그 반대)을 명확하게 대조할 때 씁니다.',
      ruleKo: '동사 현재: -는 반면에, 형용사: -(으)ㄴ 반면에',
      examplesKo: [
        '도시는 생활이 편리한 반면에 주거 비용이 비싸요.',
        '형은 성격이 외향적인 반면에 동생은 조용하고 내성적입니다.',
        '이 스마트폰은 성능이 뛰어난 반면에 배터리 소모가 빨라요.',
      ],
      uzbekMeaning: 'Holbuki / Aksincha / Qarama-qarshi tarzda',
      uzbekExplanation: 'Ikki xil fakt yoki xususiyatning bir-biriga qarama-qarshi ekanligini ifodalaydi.',
      russianMeaning: 'В то время как... / С другой стороны',
      russianExplanation: 'Используется для четкого сопоставления противоположных сторон или качеств.',
      englishMeaning: 'While / On the other hand / In contrast',
      englishExplanation: 'Contrasts two opposing facts or qualities.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄹ 텐데',
      category: '조건·가정',
      level: 3,
      meaningKo: '화자의 추측이나 상황을 전제로 제시하며 뒤에 질문이나 조언이 옴',
      explanationKo: '강한 추측이나 예정된 상황을 앞 절에 제시하고, 뒤 절에서 배려, 조언, 질문 등을 전개할 때 쓰입니다.',
      ruleKo: '동사/형용사 + -(으)ㄹ 텐데 (과거 -았/었을 텐데)',
      examplesKo: [
        '퇴근길에 차가 많이 막힐 텐데 지하철을 타세요.',
        '하루 종일 일하느라 많이 피곤했을 텐데 어서 쉬세요.',
        '내일 비가 올 텐데 우산을 미리 챙기는 게 좋겠어요.',
      ],
      uzbekMeaning: 'Kerak / Bo‘lsa kerak (tahmin qilib taklif/maslahat berish)',
      uzbekExplanation: 'Kuchli taxmin yoki vaziyatni asos qilib olib, orqa gapda maslahat yoki taklif berishda ishlatiladi.',
      russianMeaning: 'Наверное... / Должно быть... (предпосылка для совета)',
      russianExplanation: 'Выражает сильное предположение, служащее фоном или предпосылкой для последующего совета или вопроса.',
      englishMeaning: 'It is likely that... so / It must be... so',
      englishExplanation: 'Presents a strong supposition as context for a subsequent suggestion, advice, or question.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㅁ에도 불구하고',
      category: '대조·양보',
      level: 4,
      meaningKo: '앞선 어려움이나 조건에 영향을 받지 않고 뒤의 결과를 이룸',
      explanationKo: '상식적으로 기대되는 결과와 반대되는 행동이나 결과를 강조할 때 쓰이며, 문어체나 격식 있는 담화에서 자주 등장합니다.',
      ruleKo: '동사/형용사 + -(으)ㅁ에도 불구하고, 명사 + 에도 불구하고',
      examplesKo: [
        '어려운 환경에도 불구하고 그는 꿈을 포기하지 않았습니다.',
        '충분한 준비를 했음에도 불구하고 시험장에서 실수를 했어요.',
        '악천후임에도 불구하고 구조 작업이 계속 진행되고 있습니다.',
      ],
      uzbekMeaning: '...ga qaramasdan / ... bo‘lishiga qaramay',
      uzbekExplanation: 'Kutilgan to‘siq yoki holatga qaramay, harakat davom etganini yoki natijaga erishilganini ifodalaydi.',
      russianMeaning: 'Несмотря на то, что... / Вопреки',
      russianExplanation: 'Подчеркивает, что действие произошло вопреки очевидному препятствию или условию.',
      englishMeaning: 'In spite of / Despite',
      englishExplanation: 'Indicates that the following result occurred regardless of the obstacle mentioned in the first clause.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄹ 정도로',
      category: '이유·원인',
      level: 3,
      meaningKo: '어떤 상태나 행동이 그에 준하는 정도에 이름',
      explanationKo: '상태나 행동의 심각성, 정도, 강도를 비유적이거나 구체적인 상황에 빗대어 강조할 때 씁니다.',
      ruleKo: '동사/형용사 + -(으)ㄹ 정도로 / -(으)ㄹ 정도이다',
      examplesKo: [
        '목소리가 안 나올 정도로 감기가 심하게 걸렸어요.',
        '눈을 뜰 수 없을 정도로 바람이 거세게 불었습니다.',
        '눈물이 날 정도로 감동적인 영화였습니다.',
      ],
      uzbekMeaning: '... darajada / ... darajasida',
      uzbekExplanation: 'Biror holat yoki his-tuyg‘uning kuchini ta’kidlash uchun mezon ko‘rsatadi.',
      russianMeaning: 'До такой степени, что... / Настолько, что',
      russianExplanation: 'Указывает на степень интенсивности действия или состояния.',
      englishMeaning: 'To the extent that / So much that',
      englishExplanation: 'Emphasizes the degree or intensity of an action or state.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄹ 리가 없다',
      category: '조건·가정',
      level: 3,
      meaningKo: '그런 일이나 가능성이 결코 있을 수 없음을 강하게 확신함',
      explanationKo: '상식, 증거, 경험에 비추어 볼 때 그런 일이 일어날 가능성이 전혀 없다고 확신할 때 씁니다.',
      ruleKo: '동사/형용사 + -(으)ㄹ 리가 없다 (과거 -았/었을 리가 없다)',
      examplesKo: [
        '그 성실한 친구가 약속을 잊었을 리가 없어요.',
        '열심히 준비했으니 이번 시험에 실패할 리가 없습니다.',
        '방금 통화했는데 그 소식이 거짓말일 리가 없어요.',
      ],
      uzbekMeaning: 'Bo‘lishi mumkin emas / Bo‘lish ehtimoli yo‘q',
      uzbekExplanation: 'Biror narsaning yuz berishi mutlaqo imkonsiz ekanligiga qat’iy ishonchni bildiradi.',
      russianMeaning: 'Не может быть, чтобы... / Нет никаких оснований',
      russianExplanation: 'Выражает уверенность говорящего в невозможности чего-либо.',
      englishMeaning: 'There is no way that / It is impossible that',
      englishExplanation: 'Expresses strong conviction that something is impossible or cannot be true.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄹ 만하다',
      category: '기타',
      level: 3,
      meaningKo: '어떤 일을 할 만한 가치가 있거나 충분히 가능함',
      explanationKo: '어떤 대상을 추천할 만한 가치가 있을 때 쓰이며, 어떤 상태를 견딜 만하거나 타당함을 나타냅니다.',
      ruleKo: '동사 + -(으)ㄹ 만하다',
      examplesKo: [
        '이 책은 한국 역사에 관심이 있다면 꼭 읽어 볼 만해요.',
        '불편하지만 며칠 동안은 참을 만합니다.',
        '이번 시험 점수는 노력한 만큼 만족할 만한 결과예요.',
      ],
      uzbekMeaning: 'Arziydi / ... qilishga arziydigan',
      uzbekExplanation: 'Biror ishni qilishga arziydigan darajada qadrli yoki yetarli ekanligini ifodalaydi.',
      russianMeaning: 'Стоит того, чтобы... / Заслуживает',
      russianExplanation: 'Означает, что предмет или действие заслуживает внимания или вполне терпимо.',
      englishMeaning: 'Worth doing / Tolerable / Commendable',
      englishExplanation: 'Indicates that something is worth doing or is reasonably satisfactory.',
    ),
    _SeedGrammar(
      pattern: '-다 보니',
      category: '시간·순서',
      level: 3,
      meaningKo: '어떤 행동을 지속적으로 하다 보니 새로운 사실을 깨닫거나 어떤 상태가 됨',
      explanationKo: '과거부터 어떤 행동을 계속한 결과로 새로운 사실을 알게 되었거나 자연스럽게 어떤 상태에 이르렀음을 나타냅니다.',
      ruleKo: '동사 + -다 보니 (형용사 결합 불가)',
      examplesKo: [
        '매일 한국어 단어를 외우다 보니 실력이 부쩍 늘었어요.',
        '한국에서 오래 살다 보니 한국 음식에 익숙해졌습니다.',
        '일에만 몰두하다 보니 벌써 퇴근 시간이 다 되었네요.',
      ],
      uzbekMeaning: '... qilaverib / Davomiy qilib ko‘rgach',
      uzbekExplanation: 'Biror harakatni davomli qilish natijasida yangi holat yuzaga kelganini bildiradi.',
      russianMeaning: 'Поскольку делал что-то (и в результате понял/привык)',
      russianExplanation: 'Выражает результат или открытие, возникшее в процессе регулярного выполнения действия.',
      englishMeaning: 'While continually doing / As a result of repeatedly doing',
      englishExplanation: 'Indicates that after continuously doing an action, one discovered a fact or reached a certain state.',
    ),
    _SeedGrammar(
      pattern: '-(으)ㄹ 뻔하다',
      category: '기타',
      level: 3,
      meaningKo: '어떤 위험하거나 안 좋은 일이 일어날 뻔했으나 실제로는 일어나지 않음',
      explanationKo: '자칫하면 큰일이 날 뻔한 위기 상황을 가까스로 모면했음을 안도하며 말할 때 주로 씁니다.',
      ruleKo: '동사 + -(으)ㄹ 뻔했다 (대부분 과거형으로 결합)',
      examplesKo: [
        '빙판길에서 미끄러져서 크게 다칠 뻔했어요.',
        '알람이 울리지 않아서 비행기를 놓칠 뻔했습니다.',
        '너무 놀라서 들고 있던 컵을 떨어뜨릴 뻔했어요.',
      ],
      uzbekMeaning: 'Oz qolsa ... bo‘lar edi (lekin yuz bermadi)',
      uzbekExplanation: 'Salbiy yoki xavfli vaziyat deyarli yuz berishiga oz qolgani, lekin omon qolinganini bildiradi.',
      russianMeaning: 'Чуть не... / Едва не...',
      russianExplanation: 'Означает, что нежелательное действие едва не произошло, но в итоге обошлось.',
      englishMeaning: 'Almost / Nearly happened (but didn’t)',
      englishExplanation: 'Indicates that something dangerous or undesirable almost happened, but was avoided.',
    ),
  ];

  /// 선택된 텍스트와 주변 지문 문맥을 기반으로 문법 패턴을 인식하고,
  /// 사용자의 설정 언어로 해설과 예문 3개를 생성합니다.
  static Future<AiGrammarDetail> analyzeGrammar({
    required String selectedText,
    String? contextSentence,
    required String targetLang,
  }) async {
    final cleanSelection = selectedText
        .replaceAll(RegExp(r'''[()[\]{}「」『』"'“”‘’,\.!?~·…\n\r]'''), '')
        .trim();

    final cacheKey = '$cleanSelection-$targetLang';
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (contextSentence != null && cached.contextSentence == null) {
        return cached.copyWith(contextSentence: contextSentence);
      }
      return cached;
    }

    // 1. 시드 문법 및 패턴 매칭
    _SeedGrammar? matchedSeed;

    for (final seed in _seedGrammars) {
      final normalizedPattern = seed.pattern
          .replaceAll('-(으)', '')
          .replaceAll('-아/어', '')
          .replaceAll('-(으)ㄴ/는', '')
          .replaceAll('-(으)ㄹ', '')
          .replaceAll('-', '')
          .trim();

      if (cleanSelection.contains(normalizedPattern) ||
          seed.pattern.contains(cleanSelection)) {
        matchedSeed = seed;
        break;
      }
    }

    // 매칭되지 않았을 때 접미사/어미 기반 매칭
    if (matchedSeed == null) {
      if (cleanSelection.contains('바람에')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-는 바람에');
      } else if (cleanSelection.contains('뿐만')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄹ 뿐만 아니라');
      } else if (cleanSelection.contains('느라고') || cleanSelection.contains('느라')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-느라고');
      } else if (cleanSelection.contains('대신에') || cleanSelection.contains('대신')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄴ/는 대신에');
      } else if (cleanSelection.contains('반면에') || cleanSelection.contains('반면')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄴ/는 반면에');
      } else if (cleanSelection.contains('텐데') || cleanSelection.contains('테니')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄹ 텐데');
      } else if (cleanSelection.contains('불구하고')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㅁ에도 불구하고');
      } else if (cleanSelection.contains('정도')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄹ 정도로');
      } else if (cleanSelection.contains('리가')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄹ 리가 없다');
      } else if (cleanSelection.contains('만하다') || cleanSelection.contains('만해')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄹ 만하다');
      } else if (cleanSelection.contains('다 보니') || cleanSelection.contains('다보니')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-다 보니');
      } else if (cleanSelection.contains('뻔')) {
        matchedSeed = _seedGrammars.firstWhere((s) => s.pattern == '-(으)ㄹ 뻔하다');
      }
    }

    final String patternName = matchedSeed?.pattern ?? '-$cleanSelection';
    final String category = matchedSeed?.category ?? '기타 문법';
    final int level = matchedSeed?.level ?? 3;

    // 2. 다국어 해설 번역
    String meaning = '';
    String explanation = '';
    String rule = '';

    if (targetLang == 'ko') {
      meaning = matchedSeed?.meaningKo ?? '문맥 속 핵심 문법 표현입니다.';
      explanation = matchedSeed?.explanationKo ?? '선택하신 문법 표현의 문맥적 쓰임과 결합 제약을 학습하세요.';
      rule = matchedSeed?.ruleKo ?? '동사/형용사 + $patternName';
    } else if (targetLang == 'uz' && matchedSeed?.uzbekMeaning != null) {
      meaning = matchedSeed!.uzbekMeaning!;
      explanation = matchedSeed.uzbekExplanation!;
      rule = await TranslationService.translate(
            text: matchedSeed.ruleKo,
            targetLang: 'uz',
          ) ??
          matchedSeed.ruleKo;
    } else if (targetLang == 'ru' && matchedSeed?.russianMeaning != null) {
      meaning = matchedSeed!.russianMeaning!;
      explanation = matchedSeed.russianExplanation!;
      rule = await TranslationService.translate(
            text: matchedSeed.ruleKo,
            targetLang: 'ru',
          ) ??
          matchedSeed.ruleKo;
    } else if (targetLang == 'en' && matchedSeed?.englishMeaning != null) {
      meaning = matchedSeed!.englishMeaning!;
      explanation = matchedSeed.englishExplanation!;
      rule = await TranslationService.translate(
            text: matchedSeed.ruleKo,
            targetLang: 'en',
          ) ??
          matchedSeed.ruleKo;
    } else {
      // 기타 언어 (vi, zh, ja, fr, de 등) 또는 시드 미등록 문법은 실시간 번역
      final baseMeaning = matchedSeed?.meaningKo ?? cleanSelection;
      final baseExp = matchedSeed?.explanationKo ?? '문맥 속 문법 표현입니다.';
      final baseRule = matchedSeed?.ruleKo ?? '동사/형용사 + $cleanSelection';

      final transMeaning = await TranslationService.translate(
        text: baseMeaning,
        targetLang: targetLang,
      );
      final transExp = await TranslationService.translate(
        text: baseExp,
        targetLang: targetLang,
      );
      final transRule = await TranslationService.translate(
        text: baseRule,
        targetLang: targetLang,
      );

      meaning = transMeaning ?? baseMeaning;
      explanation = transExp ?? baseExp;
      rule = transRule ?? baseRule;
    }

    // 3. 실전 예문 생성 및 번역
    final List<String> rawExamples = matchedSeed?.examplesKo ?? [
      '시험을 준비하면서 $cleanSelection 표현을 정확하게 익혔습니다.',
      '선생님께서 $cleanSelection 문장의 뉘앙스를 자세히 설명해 주셨어요.',
      '한국인 친구와 대화할 때 $cleanSelection 표현을 자연스럽게 사용했습니다.',
    ];

    final tags = ['TOPIK 실전', '일상 대화', '심화 표현'];
    final List<AiGrammarExample> examples = [];

    for (int i = 0; i < rawExamples.length; i++) {
      final exKo = rawExamples[i];
      String exTrans = '';
      if (targetLang == 'ko') {
        exTrans = '한국어 예문입니다.';
      } else {
        final trans = await TranslationService.translate(
          text: exKo,
          targetLang: targetLang,
        );
        exTrans = trans ?? exKo;
      }

      examples.add(
        AiGrammarExample(
          korean: exKo,
          translation: exTrans,
          tag: tags[i % tags.length],
        ),
      );
    }

    // 지문 속 원문 문맥이 있다면 첫 번째 예문 앞에 지문 예문으로 추천 추가
    if (contextSentence != null && contextSentence.trim().isNotEmpty) {
      final cleanContext = contextSentence.trim();
      String transContext = '';
      if (targetLang != 'ko') {
        final trans = await TranslationService.translate(
          text: cleanContext,
          targetLang: targetLang,
        );
        transContext = trans ?? cleanContext;
      } else {
        transContext = '지문 출처 예문입니다.';
      }

      examples.insert(
        0,
        AiGrammarExample(
          korean: cleanContext,
          translation: transContext,
          tag: '지문 출처',
        ),
      );
    }

    final detail = AiGrammarDetail(
      id: 'ai-grammar-${patternName.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '')}',
      pattern: patternName,
      category: category,
      level: level,
      meaning: meaning,
      explanation: explanation,
      conjugationRule: rule,
      examples: examples,
      contextSentence: contextSentence,
      targetLang: targetLang,
      isBookmarked: false,
    );

    _cache[cacheKey] = detail;
    return detail;
  }
}

final aiGrammarProvider = FutureProvider.family<AiGrammarDetail,
    ({String text, String? contextSentence, String targetLang})>(
  (ref, params) async {
    return AiGrammarService.analyzeGrammar(
      selectedText: params.text,
      contextSentence: params.contextSentence,
      targetLang: params.targetLang,
    );
  },
);
