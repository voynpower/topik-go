class QuestionSet {
  const QuestionSet({
    required this.id,
    required this.title,
    required this.section,
    required this.level,
    required this.questions,
    this.questionCount,
    this.examKind,
  });

  final String id;
  final String title;
  final String section;
  final int level;
  final List<Question> questions;
  final int? questionCount;
  final String? examKind;

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
      questionCount:
          _asInt(json['question_count']) ??
          _asInt(json['questions_count']) ??
          (questions is List ? parsedQuestions.length : null),
      examKind: json['exam_kind']?.toString(),
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
    final mediaRaw = json['media'] ?? json['question_media'];
    final passage = json['passage'] ?? json['question_passages'];
    final questionSet = json['question_set'] ?? json['question_sets'];
    final section = json['section']?.toString() ?? '';
    final questionNumber = QuestionSet._asInt(json['question_number']) ?? 0;
    final setIdStr =
        json['set_id']?.toString() ??
        (questionSet is Map<String, dynamic>
            ? questionSet['id']?.toString()
            : null) ??
        '';

    final questionType = json['question_type']?.toString() ?? '';
    final rawId =
        json['id']?.toString() ??
        json['question_id']?.toString() ??
        json['uuid']?.toString() ??
        '';

    // Senior Dev Note: We need a unique ID for bookmarking.
    // If the server didn't provide one, we generate a specific composite ID.
    final id = rawId.isNotEmpty
        ? rawId
        : (questionNumber > 0
              ? 'p-${setIdStr.isNotEmpty ? setIdStr : 'unset'}-$questionNumber'
              : 'p-${setIdStr.isNotEmpty ? setIdStr : 'unset'}-${questionType.hashCode}');

    final rawPrompt =
        _nonEmpty([
          json['prompt']?.toString(),
          json['question_text']?.toString(),
          json['question']?.toString(),
          json['text']?.toString(),
          json['content']?.toString(),
        ]) ??
        '';
    final prompt = _scopedQuestionText(
      rawPrompt,
      questionNumber,
      keepSharedPassageContext: false,
    );

    final rawPassageText = _passageTextFromJson(
      passage,
      questionNumber: questionNumber,
    );
    final passageText = rawPassageText == null
        ? null
        : _scopedQuestionText(
            rawPassageText,
            questionNumber,
            keepSharedPassageContext: true,
          );

    var media = mediaRaw is List
        ? mediaRaw
              .whereType<Map<String, dynamic>>()
              .map(QuestionMedia.fromJson)
              .toList()
        : <QuestionMedia>[];

    final audioText = json['audio_text']?.toString().trim();
    if (audioText != null &&
        audioText.isNotEmpty &&
        !media.any(
          (m) =>
              m.mediaType.toLowerCase() == 'audio' && m.url.trim().isNotEmpty,
        )) {
      media = [
        ...media,
        QuestionMedia(
          id: rawId.isNotEmpty ? '$rawId-audio-text' : '$id-audio-text',
          mediaType: 'audio',
          url: '',
          transcript: audioText,
        ),
      ];
    }

    return Question(
      id: id,
      questionNumber: questionNumber,
      section: section,
      questionType: json['question_type']?.toString() ?? '',
      prompt: prompt,
      options: _cleanQuestionOptions(
        _questionOptionsFromJson(options),
        questionNumber,
      ),
      media: media,
      level: QuestionSet._asInt(json['level']),
      setId: setIdStr.isNotEmpty ? setIdStr : null,
      questionSetTitle: questionSet is Map<String, dynamic>
          ? questionSet['title']?.toString()
          : null,
      correctAnswer:
          json['correct_answer']?.toString() ?? json['answer']?.toString(),
      explanation: _cleanExplanation(_nonEmpty([
        json['explanation']?.toString(),
        json['sample_answer']?.toString(),
      ])),
      aiExplanation: _cleanExplanation(json['ai_explanation']?.toString()),
      difficulty: QuestionSet._asInt(json['difficulty']),
      timeLimitSeconds: QuestionSet._asInt(json['time_limit_seconds']),
      passageText: passageText,
    );
  }
}

String? _nonEmpty(List<String?> candidates) {
  for (final s in candidates) {
    if (s != null && s.trim().isNotEmpty) return s.trim();
  }
  return null;
}

String? _cleanExplanation(String? text) {
  if (text == null) return null;

  var normalized = text.trim();
  if (normalized.isEmpty) return null;

  // List of markers that indicate the start of boilerplate/meta text
  final markers = [
    '원문 문제지는',
    '정답표:',
    'question_media',
    'PDF를 확인하십시오',
  ];

  for (final marker in markers) {
    final index = normalized.indexOf(marker);
    if (index >= 0) {
      normalized = normalized.substring(0, index).trimRight();
    }
  }

  return normalized.isEmpty ? null : normalized;
}

String _scopedQuestionText(
  String text,
  int questionNumber, {
  required bool keepSharedPassageContext,
}) {
  final source = text.trim();
  if (source.isEmpty || questionNumber <= 0) return source;

  final currentMarkers = _questionMarkers(source, questionNumber);
  if (currentMarkers.isEmpty) return _stripTopikNoise(source);

  if (currentMarkers.length > 1) {
    final current = currentMarkers.last;
    final next = _firstAnyQuestionMarker(source, start: current.end);
    final end = next?.start ?? source.length;
    return _stripTopikNoise(source.substring(current.start, end).trim());
  }

  final current = currentMarkers.first;
  final hasPreviousQuestion = _hasAnyQuestionMarkerBefore(
    source,
    before: current.start,
  );
  final next = _firstAnyQuestionMarker(source, start: current.end);

  if (hasPreviousQuestion || next != null) {
    final end = next?.start ?? source.length;
    return _stripTopikNoise(source.substring(current.start, end).trim());
  }

  if (keepSharedPassageContext &&
      _looksLikePreviousListeningTranscript(source, current.start) &&
      !_hasRangeHeaderForQuestion(source, questionNumber)) {
    final end = next?.start ?? source.length;
    return _stripTopikNoise(source.substring(current.start, end).trim());
  }

  if (keepSharedPassageContext && current.start > source.length * 0.45) {
    return _stripTopikNoise(source);
  }

  if (!keepSharedPassageContext) {
    return _stripTopikNoise(source.substring(current.start).trim());
  }

  return _stripTopikNoise(source);
}

List<_TextRange> _questionMarkers(String text, int questionNumber) {
  final escaped = RegExp.escape('$questionNumber');
  final patterns = [
    RegExp('(^|\\n)\\s*\\[?$escaped\\]?\\s*[.)번]', multiLine: true),
    RegExp('(^|\\n)\\s*문제\\s*$escaped\\s*[.)번]?', multiLine: true),
    RegExp('(^|\\n)\\s*$escaped\\s', multiLine: true),
  ];

  final markers = <_TextRange>[];
  for (final pattern in patterns) {
    for (final match in pattern.allMatches(text)) {
      markers.add(_TextRange(match.start, match.end));
    }
  }

  markers.sort((a, b) => a.start.compareTo(b.start));
  return markers;
}

_TextRange? _firstAnyQuestionMarker(String text, {int start = 0}) {
  final pattern = RegExp(
    r'(^|\n)\s*(?:문제\s*)?\[?(?:[1-9]|[1-5][0-9]|60)\]?\s*[.)번]',
    multiLine: true,
  );
  final match = pattern.firstMatch(text.substring(start));
  if (match == null) return null;
  return _TextRange(match.start + start, match.end + start);
}

bool _hasAnyQuestionMarkerBefore(String text, {required int before}) {
  final marker = _firstAnyQuestionMarker(text);
  return marker != null && marker.start < before;
}

bool _looksLikePreviousListeningTranscript(String text, int before) {
  final prefix = text.substring(0, before.clamp(0, text.length));
  return prefix.contains('남자') || prefix.contains('여자');
}

bool _hasRangeHeaderForQuestion(String text, int questionNumber) {
  final pattern = RegExp(r'※\s*\[?(\d{1,2})\s*~\s*(\d{1,2})\]?');
  for (final match in pattern.allMatches(text)) {
    final start = int.tryParse(match.group(1) ?? '');
    final end = int.tryParse(match.group(2) ?? '');
    if (start != null &&
        end != null &&
        questionNumber >= start &&
        questionNumber <= end) {
      return true;
    }
  }
  return false;
}

String _stripTopikNoise(String text) {
  final lines = text.split('\n').map((line) => line.trimRight()).where((line) {
    final normalized = line.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    if (normalized.contains('test of proficiency in korean')) return false;
    if (normalized.contains('tesk ot prolciensyin korean')) return false;
    if (normalized.startsWith('topik 제102회')) return false;
    if (normalized.startsWith(') topik 제102회')) return false;
    return true;
  }).toList();
  return lines.join('\n').trim();
}

List<QuestionOption> _cleanQuestionOptions(
  List<QuestionOption> options,
  int questionNumber,
) {
  if (questionNumber <= 0) return options;
  return [
    for (final option in options)
      QuestionOption(
        id: option.id,
        label: option.label,
        text: _stripOptionLeak(option.text, questionNumber),
        optionNumber: option.optionNumber,
      ),
  ];
}

String _stripOptionLeak(String text, int questionNumber) {
  var cleaned = text.trim();
  for (var number = questionNumber + 1; number <= 60; number++) {
    final marker = _firstQuestionMarker(cleaned, number);
    if (marker != null) {
      cleaned = cleaned.substring(0, marker.start).trim();
      break;
    }
  }
  return _stripTopikNoise(cleaned);
}

_TextRange? _firstQuestionMarker(
  String text,
  int questionNumber, {
  int start = 0,
}) {
  final markers = _questionMarkers(text.substring(start), questionNumber);
  if (markers.isEmpty) return null;
  final first = markers.first;
  return _TextRange(first.start + start, first.end + start);
}

class _TextRange {
  const _TextRange(this.start, this.end);

  final int start;
  final int end;
}

String? _passageTextFromJson(Object? passage, {int? questionNumber}) {
  if (passage is String) {
    final t = passage.trim();
    return t.isEmpty ? null : t;
  }
  if (passage is Map<String, dynamic>) {
    return _nonEmpty([
      passage['passage_text']?.toString(),
      passage['text']?.toString(),
      passage['content']?.toString(),
      passage['body']?.toString(),
    ]);
  }
  if (passage is List) {
    final parsed = passage.whereType<Map<String, dynamic>>().toList();
    final matched = _matchingPassage(parsed, questionNumber);
    if (matched != null) {
      return _passageTextFromJson(matched, questionNumber: questionNumber);
    }

    for (final item in passage) {
      final text = _passageTextFromJson(item, questionNumber: questionNumber);
      if (text != null && text.trim().isNotEmpty) return text;
    }
  }
  return null;
}

Map<String, dynamic>? _matchingPassage(
  List<Map<String, dynamic>> passages,
  int? questionNumber,
) {
  if (questionNumber == null || questionNumber <= 0) return null;

  for (final passage in passages) {
    final candidate =
        QuestionSet._asInt(passage['question_number']) ??
        QuestionSet._asInt(passage['number']) ??
        QuestionSet._asInt(passage['start_question_number']);
    if (candidate == questionNumber) return passage;

    final start = QuestionSet._asInt(passage['start_question_number']);
    final end = QuestionSet._asInt(passage['end_question_number']);
    if (start != null &&
        end != null &&
        questionNumber >= start &&
        questionNumber <= end) {
      return passage;
    }
  }

  return null;
}

List<QuestionOption> _questionOptionsFromJson(Object? options) {
  if (options is! List || options.isEmpty) return const [];

  if (options.every((e) => e is String)) {
    return [
      for (var i = 0; i < options.length; i++)
        QuestionOption(
          id: '${i + 1}',
          label: '${i + 1}',
          text: options[i]! as String,
          optionNumber: i + 1,
        ),
    ];
  }

  final parsed = options
      .whereType<Map<String, dynamic>>()
      .map(QuestionOption.fromJson)
      .toList();
  parsed.sort(
    (a, b) => (a.optionNumber ?? 999).compareTo(b.optionNumber ?? 999),
  );
  return parsed;
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
          json['option']?.toString() ??
          json['content']?.toString() ??
          json['body']?.toString() ??
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
    final url =
        json['url']?.toString() ??
        json['media_url']?.toString() ??
        json['file_url']?.toString() ??
        json['audio_url']?.toString() ??
        json['src']?.toString() ??
        json['path']?.toString() ??
        '';
    return QuestionMedia(
      id: json['id']?.toString() ?? '',
      mediaType:
          json['media_type']?.toString() ?? json['type']?.toString() ?? '',
      url: url,
      transcript:
          json['transcript']?.toString() ?? json['audio_text']?.toString(),
      durationSeconds: QuestionSet._asInt(json['duration_seconds']),
    );
  }
}
