class KeyVocabularyItem {
  const KeyVocabularyItem({
    required this.korean,
    required this.translation,
  });

  final String korean;
  final String translation;

  factory KeyVocabularyItem.fromJson(Map<String, dynamic> json) {
    return KeyVocabularyItem(
      korean: json['korean']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
    );
  }
}

class QuestionAiExplanation {
  const QuestionAiExplanation({
    required this.questionId,
    required this.selectedOption,
    required this.correctAnswer,
    required this.isCorrect,
    required this.languageCode,
    required this.wrongReason,
    required this.correctReason,
    required this.keyVocabulary,
    required this.tip,
    required this.rawExplanationText,
    required this.source,
  });

  final String questionId;
  final String selectedOption;
  final String correctAnswer;
  final bool isCorrect;
  final String languageCode;
  final String wrongReason;
  final String correctReason;
  final List<KeyVocabularyItem> keyVocabulary;
  final String tip;
  final String rawExplanationText;
  final String source;

  factory QuestionAiExplanation.fromJson(Map<String, dynamic> json) {
    final explanationObj = json['explanation'] is Map<String, dynamic>
        ? json['explanation'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawVocab = explanationObj['keyVocabulary'];
    final keyVocabulary = <KeyVocabularyItem>[];
    if (rawVocab is List) {
      for (final item in rawVocab) {
        if (item is Map<String, dynamic>) {
          keyVocabulary.add(KeyVocabularyItem.fromJson(item));
        }
      }
    }

    return QuestionAiExplanation(
      questionId: json['questionId']?.toString() ?? '',
      selectedOption: json['selectedOption']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      languageCode: json['languageCode']?.toString() ?? 'uz',
      wrongReason: explanationObj['wrongReason']?.toString() ?? '',
      correctReason: explanationObj['correctReason']?.toString() ?? '',
      keyVocabulary: keyVocabulary,
      tip: explanationObj['tip']?.toString() ?? '',
      rawExplanationText: json['rawExplanationText']?.toString() ?? '',
      source: json['source']?.toString() ?? 'ai',
    );
  }
}

class WritingGrammarCorrectionItem {
  const WritingGrammarCorrectionItem({
    required this.original,
    required this.corrected,
    required this.reason,
  });

  final String original;
  final String corrected;
  final String reason;

  factory WritingGrammarCorrectionItem.fromJson(Map<String, dynamic> json) {
    return WritingGrammarCorrectionItem(
      original: json['original']?.toString() ?? '',
      corrected: json['corrected']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class QuestionAiWritingFeedback {
  const QuestionAiWritingFeedback({
    required this.questionId,
    required this.userAnswer,
    required this.languageCode,
    required this.scoreEstimate,
    required this.grammarCorrections,
    required this.deductionPoints,
    required this.polishedVersion,
    required this.nativeFeedback,
    required this.keyVocabulary,
    required this.source,
  });

  final String questionId;
  final String userAnswer;
  final String languageCode;
  final String scoreEstimate;
  final List<WritingGrammarCorrectionItem> grammarCorrections;
  final String deductionPoints;
  final String polishedVersion;
  final String nativeFeedback;
  final List<KeyVocabularyItem> keyVocabulary;
  final String source;

  factory QuestionAiWritingFeedback.fromJson(Map<String, dynamic> json) {
    final feedbackObj = json['feedback'] is Map<String, dynamic>
        ? json['feedback'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawCorrections = feedbackObj['grammarCorrections'];
    final grammarCorrections = <WritingGrammarCorrectionItem>[];
    if (rawCorrections is List) {
      for (final item in rawCorrections) {
        if (item is Map<String, dynamic>) {
          grammarCorrections.add(WritingGrammarCorrectionItem.fromJson(item));
        }
      }
    }

    final rawVocab = feedbackObj['keyVocabulary'];
    final keyVocabulary = <KeyVocabularyItem>[];
    if (rawVocab is List) {
      for (final item in rawVocab) {
        if (item is Map<String, dynamic>) {
          keyVocabulary.add(KeyVocabularyItem.fromJson(item));
        }
      }
    }

    return QuestionAiWritingFeedback(
      questionId: json['questionId']?.toString() ?? '',
      userAnswer: json['userAnswer']?.toString() ?? '',
      languageCode: json['languageCode']?.toString() ?? 'uz',
      scoreEstimate: feedbackObj['scoreEstimate']?.toString() ?? '',
      grammarCorrections: grammarCorrections,
      deductionPoints: feedbackObj['deductionPoints']?.toString() ?? '',
      polishedVersion: feedbackObj['polishedVersion']?.toString() ?? '',
      nativeFeedback: feedbackObj['nativeFeedback']?.toString() ?? '',
      keyVocabulary: keyVocabulary,
      source: json['source']?.toString() ?? 'ai',
    );
  }
}

