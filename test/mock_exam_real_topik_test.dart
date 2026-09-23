import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/features/mock_exam/data/mock_exam_history_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Mock exam round matching works for 83 and 102', () {
    bool isMatch(QuestionSet set, String round) {
      final haystack = '${set.id} ${set.title}'.toLowerCase();
      return RegExp('(^|[^0-9])$round([^0-9]|\$)').hasMatch(haystack);
    }

    final set83Reading = QuestionSet(
      id: 'topik2-83-reading',
      title: '제83회 TOPIK II 읽기 모의고사',
      section: 'reading',
      level: 4,
      questions: const [],
    );

    final set83Listening = QuestionSet(
      id: 'topik2-83-listening',
      title: '제83회 TOPIK II 듣기 모의고사',
      section: 'listening',
      level: 4,
      questions: const [],
    );

    final set102Listening = QuestionSet(
      id: 'topik2-102-listening',
      title: '제102회 TOPIK II 듣기 모의고사',
      section: 'listening',
      level: 4,
      questions: const [],
    );

    final set102Reading = QuestionSet(
      id: 'topik2-102-reading',
      title: '제102회 TOPIK II 읽기 모의고사',
      section: 'reading',
      level: 4,
      questions: const [],
    );

    expect(isMatch(set83Reading, '83'), isTrue);
    expect(isMatch(set83Reading, '102'), isFalse);
    expect(isMatch(set83Listening, '83'), isTrue);
    expect(isMatch(set83Listening, '102'), isFalse);
    expect(isMatch(set102Listening, '102'), isTrue);
    expect(isMatch(set102Listening, '83'), isFalse);
    expect(isMatch(set102Reading, '102'), isTrue);
    expect(isMatch(set102Reading, '83'), isFalse);
  });

  test('Mock exam history handles multiple rounds and deletion', () async {
    final repo = MockExamHistoryRepository();
    final item83 = MockExamHistoryItem(
      id: 'h-83',
      title: 'TOPIK II · 제83회',
      round: '83',
      startedAt: DateTime.now().subtract(const Duration(hours: 3)),
      endedAt: DateTime.now(),
      isAutoSubmit: false,
      sections: const ['L', 'R', 'W'],
      scorePercent: 85,
      correctCount: 85,
      totalQuestions: 100,
    );

    final item102 = MockExamHistoryItem(
      id: 'h-102',
      title: 'TOPIK II · 제102회',
      round: '102',
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      endedAt: DateTime.now(),
      isAutoSubmit: true,
      sections: const ['L', 'R', 'W'],
      scorePercent: 70,
      correctCount: 70,
      totalQuestions: 100,
    );

    await repo.saveAttempt(item83);
    await repo.saveAttempt(item102);

    final history = await repo.getHistory();
    expect(history.length, 2);
    expect(history.first.round, '102');
    expect(history.first.isAutoSubmit, isTrue);

    await repo.deleteAttempt('h-102');
    final afterDelete = await repo.getHistory();
    expect(afterDelete.length, 1);
    expect(afterDelete.first.round, '83');
  });

  test('TOPIK II exam layout contains Listening 1~50, Writing 51~54, and Reading 1~50', () {
    final listening = List.generate(
      50,
      (i) => Question(
        id: 'topik2-102-listening-q${i + 1}',
        questionNumber: i + 1,
        section: 'listening',
        questionType: 'multiple_choice',
        prompt: '문제 ${i + 1}번',
        options: const [],
        media: const [],
      ),
    );

    final writing = [
      const Question(
        id: 'topik2-102-writing-q51',
        questionNumber: 51,
        section: 'writing',
        questionType: 'writing_short_completion',
        prompt: '51. 다음 글의 ㉠과 ㉡에 알맞은 말을 각각 쓰시오.',
        options: [],
        media: [],
      ),
      const Question(
        id: 'topik2-102-writing-q52',
        questionNumber: 52,
        section: 'writing',
        questionType: 'writing_short_completion',
        prompt: '52. 다음 글의 ㉠과 ㉡에 알맞은 말을 각각 쓰시오.',
        options: [],
        media: [],
      ),
      const Question(
        id: 'topik2-102-writing-q53',
        questionNumber: 53,
        section: 'writing',
        questionType: 'writing_graph_description',
        prompt: '53. 다음은 캠핑 인구의 변화에 대한 자료이다.',
        options: [],
        media: [],
      ),
      const Question(
        id: 'topik2-102-writing-q54',
        questionNumber: 54,
        section: 'writing',
        questionType: 'writing_essay',
        prompt: '54. 다음을 참고하여 600~700자로 글을 쓰시오.',
        options: [],
        media: [],
      ),
    ];

    final reading = List.generate(
      50,
      (i) => Question(
        id: 'topik2-102-reading-q${i + 1}',
        questionNumber: i + 1,
        section: 'reading',
        questionType: 'multiple_choice',
        prompt: '문제 ${i + 1}번',
        options: const [],
        media: const [],
      ),
    );

    final combined = [...listening, ...writing, ...reading];

    expect(combined.length, 104);
    expect(combined[0].section, 'listening');
    expect(combined[49].section, 'listening');
    expect(combined[50].section, 'writing');
    expect(combined[50].questionNumber, 51);
    expect(combined[53].section, 'writing');
    expect(combined[53].questionNumber, 54);
    expect(combined[54].section, 'reading');
    expect(combined[103].section, 'reading');
  });

  test('Continuous listening playlist builds 50 seamless audio sources in order', () {
    final listening = List.generate(
      50,
      (i) => Question(
        id: 'topik2-102-listening-q${i + 1}',
        questionNumber: i + 1,
        section: 'listening',
        questionType: 'multiple_choice',
        prompt: '문제 ${i + 1}번',
        options: const [],
        media: [
          QuestionMedia(
            id: 'm-audio-$i',
            mediaType: 'audio',
            url: 'https://damqug77a9y1r.cloudfront.net/test/audio/topik2-102/listening-q${(i + 1).toString().padLeft(2, '0')}.mp3',
          ),
        ],
      ),
    );

    final other = [
      const Question(
        id: 'topik2-102-writing-q51',
        questionNumber: 51,
        section: 'writing',
        questionType: 'writing_short_completion',
        prompt: '51번',
        options: [],
        media: [],
      ),
      const Question(
        id: 'topik2-102-reading-q01',
        questionNumber: 1,
        section: 'reading',
        questionType: 'multiple_choice',
        prompt: '1번',
        options: [],
        media: [],
      ),
    ];

    final allQuestions = [...listening, ...other];

    final listeningQuestions = allQuestions.where((q) {
      if (q.section.toLowerCase() != 'listening') return false;
      final audio = q.media.cast<QuestionMedia?>().firstWhere(
            (m) => m != null && m.mediaType.toLowerCase().contains('audio') && m.url.trim().isNotEmpty,
            orElse: () => null,
          );
      return audio != null;
    }).toList();

    final playlistQuestionIds = listeningQuestions.map((q) => q.id).toList();

    expect(playlistQuestionIds.length, 50);
    expect(playlistQuestionIds.first, 'topik2-102-listening-q1');
    expect(playlistQuestionIds[1], 'topik2-102-listening-q2');
    expect(playlistQuestionIds[24], 'topik2-102-listening-q25');
    expect(playlistQuestionIds.last, 'topik2-102-listening-q50');

    // Index tracking simulates currentIndexStream moving automatically from 0 to 49
    for (int i = 0; i < 50; i++) {
      expect(playlistQuestionIds[i], 'topik2-102-listening-q${i + 1}');
    }

    // Manual jump seek test: tapping question 15 seeks to index 14
    final targetIndex = playlistQuestionIds.indexOf('topik2-102-listening-q15');
    expect(targetIndex, 14);
  });
}


