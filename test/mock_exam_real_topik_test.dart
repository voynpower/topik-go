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
      id: 'topik-83-reading',
      title: 'TOPIK 83회 읽기 기출문제',
      section: 'reading',
      level: 3,
      questions: const [],
    );

    final set102Listening = QuestionSet(
      id: 'topik2-102-listening',
      title: 'TOPIK 제102회 듣기 기출문제',
      section: 'listening',
      level: 4,
      questions: const [],
    );

    expect(isMatch(set83Reading, '83'), isTrue);
    expect(isMatch(set83Reading, '102'), isFalse);
    expect(isMatch(set102Listening, '102'), isTrue);
    expect(isMatch(set102Listening, '83'), isFalse);
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
}
