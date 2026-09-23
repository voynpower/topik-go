import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/features/mock_exam/data/mock_exam_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('MockExamHistoryItem serialization works correctly', () {
    final item = MockExamHistoryItem(
      id: 'test-1',
      title: 'TOPIK II · 제83회',
      round: '83',
      startedAt: DateTime.parse('2026-09-20 05:26:00'),
      endedAt: DateTime.parse('2026-09-20 08:26:00'),
      isAutoSubmit: true,
      sections: const ['L', 'R', 'W'],
      scorePercent: 78,
      correctCount: 78,
      totalQuestions: 100,
    );

    final json = item.toJson();
    final restored = MockExamHistoryItem.fromJson(json);

    expect(restored.id, 'test-1');
    expect(restored.title, 'TOPIK II · 제83회');
    expect(restored.round, '83');
    expect(restored.isAutoSubmit, isTrue);
    expect(restored.sections, ['L', 'R', 'W']);
    expect(restored.scorePercent, 78);
    expect(restored.correctCount, 78);
    expect(restored.totalQuestions, 100);
  });

  test('MockExamHistoryRepository save, get and delete', () async {
    final repo = MockExamHistoryRepository();

    expect(await repo.getHistory(), isEmpty);

    final item1 = MockExamHistoryItem(
      id: 'item-1',
      title: 'TOPIK II · 제83회',
      round: '83',
      startedAt: DateTime.now(),
      endedAt: DateTime.now(),
      isAutoSubmit: false,
      sections: const ['L', 'R', 'W'],
    );
    await repo.saveAttempt(item1);

    final listAfter1 = await repo.getHistory();
    expect(listAfter1.length, 1);
    expect(listAfter1.first.id, 'item-1');

    final item2 = MockExamHistoryItem(
      id: 'item-2',
      title: 'TOPIK II · 제102회',
      round: '102',
      startedAt: DateTime.now(),
      endedAt: DateTime.now(),
      isAutoSubmit: true,
      sections: const ['L', 'R'],
    );
    await repo.saveAttempt(item2);

    final listAfter2 = await repo.getHistory();
    expect(listAfter2.length, 2);
    expect(listAfter2.first.id, 'item-2'); // newly saved is prepended

    await repo.deleteAttempt('item-1');
    final listAfterDelete = await repo.getHistory();
    expect(listAfterDelete.length, 1);
    expect(listAfterDelete.first.id, 'item-2');
  });
}

