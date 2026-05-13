class QuestionSet {
  const QuestionSet({
    required this.id,
    required this.title,
    required this.section,
    required this.level,
    required this.questions,
    this.questionCount,
  });

  final String id;
  final String title;
  final String section;
  final int level;
  final List<Question> questions;
  final int? questionCount;

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'];
    final parsedQuestions = questions is List
        ? questions
              .whereType<Map<String, dynamic>>()
              .map(Question.fromJson)
              .toList()
        : <Question>[];

    return QuestionSet(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled question set',
      section: json['section']?.toString() ?? 'unknown',
      level: _asInt(json['level']) ?? 0,
      questions: parsedQuestions,
      questionCount: questions is List ? parsedQuestions.length : null,
    );
  }

  String get sectionLabel {
    switch (section.toLowerCase()) {
      case 'reading':
        return '읽기';
      case 'listening':
        return '듣기';
      case 'writing':
        return '쓰기';
      default:
        return section;
    }
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class Question {
  const Question({
    required this.id,
    required this.questionNumber,
    required this.section,
    required this.questionType,
    required this.prompt,
    required this.options,
    required this.media,
    this.level,
    this.setId,
    this.questionSetTitle,
    this.correctAnswer,
    this.explanation,
    this.aiExplanation,
    this.difficulty,
    this.timeLimitSeconds,
    this.passageText,
  });

  final String id;
  final int questionNumber;
  final String section;
  final String questionType;
  final String prompt;
  final List<QuestionOption> options;
  final List<QuestionMedia> media;
  final int? level;
  final String? setId;
  final String? questionSetTitle;
  final String? correctAnswer;
  final String? explanation;
  final String? aiExplanation;
  final int? difficulty;
  final int? timeLimitSeconds;
  final String? passageText;

  factory Question.fromJson(Map<String, dynamic> json) {
    final options = json['options'] ?? json['question_options'];
    final media = json['media'] ?? json['question_media'];
    final passage = json['passage'] ?? json['question_passages'];
    final questionSet = json['question_set'] ?? json['question_sets'];

    return Question(
      id: json['id']?.toString() ?? '',
      questionNumber: QuestionSet._asInt(json['question_number']) ?? 0,
      section: json['section']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      options: options is List
          ? options
                .whereType<Map<String, dynamic>>()
                .map(QuestionOption.fromJson)
                .toList()
          : const [],
      media: media is List
          ? media
                .whereType<Map<String, dynamic>>()
                .map(QuestionMedia.fromJson)
                .toList()
          : const [],
      level: QuestionSet._asInt(json['level']),
      setId:
          json['set_id']?.toString() ??
          (questionSet is Map<String, dynamic>
              ? questionSet['id']?.toString()
              : null),
      questionSetTitle: questionSet is Map<String, dynamic>
          ? questionSet['title']?.toString()
          : null,
      correctAnswer: json['correct_answer']?.toString(),
      explanation: json['explanation']?.toString(),
      aiExplanation: json['ai_explanation']?.toString(),
      difficulty: QuestionSet._asInt(json['difficulty']),
      timeLimitSeconds: QuestionSet._asInt(json['time_limit_seconds']),
      passageText: passage is Map<String, dynamic>
          ? passage['passage_text']?.toString() ??
                passage['text']?.toString() ??
                passage['content']?.toString()
          : null,
    );
  }
}

class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.label,
    required this.text,
    this.optionNumber,
  });

  final String id;
  final String label;
  final String text;
  final int? optionNumber;

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    final optionNumber = QuestionSet._asInt(json['option_number']);
    return QuestionOption(
      id: json['id']?.toString() ?? '',
      label:
          json['label']?.toString() ??
          json['option_label']?.toString() ??
          json['option_key']?.toString() ??
          optionNumber?.toString() ??
          '',
      text:
          json['text']?.toString() ??
          json['option_text']?.toString() ??
          json['content']?.toString() ??
          '',
      optionNumber: optionNumber,
    );
  }
}

class QuestionMedia {
  const QuestionMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    this.transcript,
    this.durationSeconds,
  });

  final String id;
  final String mediaType;
  final String url;
  final String? transcript;
  final int? durationSeconds;

  factory QuestionMedia.fromJson(Map<String, dynamic> json) {
    return QuestionMedia(
      id: json['id']?.toString() ?? '',
      mediaType:
          json['media_type']?.toString() ?? json['type']?.toString() ?? '',
      url: json['url']?.toString() ?? json['media_url']?.toString() ?? '',
      transcript: json['transcript']?.toString(),
      durationSeconds: QuestionSet._asInt(json['duration_seconds']),
    );
  }
}
