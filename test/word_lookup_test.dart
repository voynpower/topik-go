import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';
import 'package:topik_go/features/questions/presentation/listening_practice_page.dart';
import 'package:topik_go/features/questions/presentation/reading_practice_page.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/presentation/word_lookup_sheet.dart';

void main() {
  group('Word lookup & practice tests', () {
    testWidgets('renders WordLookupSheet and search field', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WordLookupSheet(),
            ),
          ),
        ),
      );

      // Verify the sheet title and search field
      expect(find.text('단어 · 문법 사전'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
      'renders ReadingPracticePage with round selector, clean buttons without numbers, and grouped questions UI',
      (tester) async {
        final sampleQuestions = List<Question>.generate(
          50,
          (i) => Question(
            id: 'topik2-102-reading-q${i + 1}',
            setId: 'topik2-102-reading',
            section: 'reading',
            questionType: 'multiple_choice',
            questionNumber: i + 1,
            prompt: i == 2
                ? '3. 지금 출발하지 않으면 약속 시간에 <u>늦을지도 모른다</u>.'
                : '${i + 1}. 알맞은 것을 고르십시오.',
            passageText:
                i >= 18 && i <= 19 ? 'Shared passage for 19~20' : null,
            options: const [
              QuestionOption(id: 'opt-1', label: '1', text: '선택지 1'),
              QuestionOption(id: 'opt-2', label: '2', text: '선택지 2'),
              QuestionOption(id: 'opt-3', label: '3', text: '선택지 3'),
              QuestionOption(id: 'opt-4', label: '4', text: '선택지 4'),
            ],
            correctAnswer: '1',
            explanation: '해설입니다.',
            media: i == 8
                ? const [
                    QuestionMedia(
                      id: 'img-9',
                      mediaType: 'image',
                      url: '/photos/reading-q09.png',
                    ),
                  ]
                : const [],
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              practiceQuestionsProvider(
                const PracticeSetQuestionsKey(
                  section: 'reading',
                  setId: 'topik2-102-reading',
                ),
              ).overrideWith(
                (ref) async => QuestionPage(
                  items: sampleQuestions,
                  page: 1,
                  limit: 50,
                  total: 50,
                ),
              ),
            ],
            child: const MaterialApp(
              home: ReadingPracticePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check title and round chips
        expect(find.text('TOPIK II 읽기 연습'), findsOneWidget);
        expect(find.text('제102회 기출 읽기 (50문항)'), findsOneWidget);
        expect(find.text('제83회 기출 읽기 (50문항)'), findsOneWidget);

        // 1st question rendered with range label
        expect(find.text('1번'), findsWidgets);
        expect(find.text('선택지 1'), findsOneWidget);

        // Problem 6: Bottom navigation shows "다음" without question numbers!
        expect(find.text('다음'), findsOneWidget);
        expect(find.text('다음 (2번)'), findsNothing);

        // Open grid sheet and tap question 19
        final gridButton = find.byTooltip('전체 문항 목록').first;
        await tester.tap(gridButton);
        await tester.pumpAndSettle();

        // Ensure question 19 is visible and tap it
        final q19Button = find.text('19');
        await tester.scrollUntilVisible(
          q19Button,
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(q19Button);
        await tester.pumpAndSettle();

        // On 19~20 group page: rangeLabel shows '19~20번'
        expect(find.text('19~20번'), findsWidgets);
        // Both 19번 and 20번 question badges are displayed on the SAME page!
        expect(find.text('19번'), findsOneWidget);
        expect(find.text('20번'), findsOneWidget);
        // Next button is cleanly "다음" and previous is cleanly "이전"
        expect(find.text('다음'), findsOneWidget);
        expect(find.text('이전'), findsOneWidget);
        expect(find.text('다음 (21~22번)'), findsNothing);
        expect(find.text('이전 (18번)'), findsNothing);
      },
    );

    testWidgets('renders underlined text for <u> without exposing raw HTML tags (Problem 1)', (
      tester,
    ) async {
      final sampleQuestions = [
        const Question(
          id: 'topik2-102-reading-q3',
          setId: 'topik2-102-reading',
          section: 'reading',
          questionType: 'multiple_choice',
          questionNumber: 3,
          prompt: '3. 지금 출발하지 않으면 약속 시간에 <u>늦을지도 모른다</u>.',
          options: [
            QuestionOption(id: 'opt-1', label: '1', text: '늦을 수 있다'),
            QuestionOption(id: 'opt-2', label: '2', text: '늦은 편이다'),
            QuestionOption(id: 'opt-3', label: '3', text: '늦을 리 없다'),
            QuestionOption(id: 'opt-4', label: '4', text: '늦기 십상이다'),
          ],
          correctAnswer: '1',
          explanation: '해설',
          media: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            practiceQuestionsProvider(
              const PracticeSetQuestionsKey(
                section: 'reading',
                setId: 'topik2-102-reading',
              ),
            ).overrideWith(
              (ref) async => QuestionPage(
                items: sampleQuestions,
                page: 1,
                limit: 1,
                total: 1,
              ),
            ),
          ],
          child: const MaterialApp(
            home: ReadingPracticePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure raw HTML tags <u> or </u> are NEVER rendered
      expect(find.textContaining('<u>'), findsNothing);
      expect(find.textContaining('</u>'), findsNothing);
      // Ensure the inner text is rendered
      expect(find.textContaining('늦을지도 모른다'), findsOneWidget);
    });

    testWidgets('Problem 5: Q46 overrides circled options with real text choices', (
      tester,
    ) async {
      final sampleQuestions = [
        const Question(
          id: 'topik2-102-reading-q46',
          setId: 'topik2-102-reading',
          section: 'reading',
          questionType: 'multiple_choice',
          questionNumber: 46,
          prompt: '46. 윗글에 나타난 필자의 태도로 가장 알맞은 것을 고르십시오.',
          options: [
            QuestionOption(id: 'opt-1', label: '1', text: '㉠'),
            QuestionOption(id: 'opt-2', label: '2', text: '㉡'),
            QuestionOption(id: 'opt-3', label: '3', text: '㉢'),
            QuestionOption(id: 'opt-4', label: '4', text: '㉣'),
          ],
          correctAnswer: '3',
          explanation: '해설',
          media: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            practiceQuestionsProvider(
              const PracticeSetQuestionsKey(
                section: 'reading',
                setId: 'topik2-102-reading',
              ),
            ).overrideWith(
              (ref) async => QuestionPage(
                items: sampleQuestions,
                page: 1,
                limit: 1,
                total: 1,
              ),
            ),
          ],
          child: const MaterialApp(
            home: ReadingPracticePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Q46 should show real text choices, NOT '㉠'
      expect(find.text('㉠'), findsNothing);
      expect(find.textContaining('해저 전선'), findsWidgets);
    });

    test('Reading question grouping pairs multi-question sets into 42 groups', () {
      int? getGroupEnd(int qNum) {
        if (qNum == 19) return 20;
        if (qNum == 21) return 22;
        if (qNum == 23) return 24;
        if (qNum == 42) return 43;
        if (qNum == 44) return 45;
        if (qNum == 46) return 47;
        if (qNum == 48) return 50;
        return null;
      }

      final sampleQuestions = List<Question>.generate(
        50,
        (i) => Question(
          id: 'q${i + 1}',
          setId: 'topik2-102-reading',
          section: 'reading',
          questionType: 'multiple_choice',
          questionNumber: i + 1,
          prompt: 'Question ${i + 1}',
          options: const [],
          correctAnswer: '1',
          explanation: '',
          media: const [],
        ),
      );

      final handled = <String>{};
      final groups = <ReadingQuestionGroup>[];

      for (int i = 0; i < sampleQuestions.length; i++) {
        final q = sampleQuestions[i];
        if (handled.contains(q.id)) continue;
        final qNum = q.questionNumber;
        final end = getGroupEnd(qNum);

        if (end != null) {
          final subList = sampleQuestions
              .where((x) => x.questionNumber >= qNum && x.questionNumber <= end)
              .toList();
          for (final item in subList) {
            handled.add(item.id);
          }
          groups.add(
            ReadingQuestionGroup(
              id: 'group-$qNum-$end',
              questions: subList,
            ),
          );
          continue;
        }

        handled.add(q.id);
        groups.add(
          ReadingQuestionGroup(
            id: q.id,
            questions: [q],
          ),
        );
      }

      // Total groups should be 42
      expect(groups.length, 42);

      // Verify specific 2-question sets
      for (final start in [19, 21, 23, 42, 44, 46]) {
        final g = groups.firstWhere((x) => x.startNumber == start);
        expect(g.questions.length, 2);
        expect(g.rangeLabel, '$start~${start + 1}번');
      }

      // Verify 3-question set 48~50
      final g48 = groups.firstWhere((x) => x.startNumber == 48);
      expect(g48.questions.length, 3);
      expect(g48.rangeLabel, '48~50번');

      // Verify total questions across all groups equals 50
      final totalQuestions =
          groups.fold<int>(0, (sum, g) => sum + g.questions.length);
      expect(totalQuestions, 50);
    });

    test('ListeningQuestionGroup pairs questions 21 to 50 correctly', () {
      final sampleQuestions = List<Question>.generate(
        50,
        (i) => Question(
          id: 'topik2-102-listening-q${i + 1}',
          setId: 'topik2-102-listening',
          section: 'listening',
          questionType: 'multiple_choice',
          questionNumber: i + 1,
          prompt: 'Question ${i + 1}',
          options: const [],
          correctAnswer: '1',
          explanation: '',
          media: const [],
        ),
      );

      final handled = <String>{};
      final groups = <ListeningQuestionGroup>[];

      for (int i = 0; i < sampleQuestions.length; i++) {
        final q = sampleQuestions[i];
        if (handled.contains(q.id)) continue;
        final qNum = q.questionNumber;
        int? groupEnd;
        if (qNum >= 21 && qNum <= 49 && qNum.isOdd) {
          groupEnd = qNum + 1;
        }

        if (groupEnd != null) {
          final subList = sampleQuestions
              .where((x) => x.questionNumber >= qNum && x.questionNumber <= groupEnd!)
              .toList();
          for (final item in subList) {
            handled.add(item.id);
          }
          groups.add(
            ListeningQuestionGroup(
              id: 'group-$qNum-$groupEnd',
              questions: subList,
            ),
          );
          continue;
        }

        handled.add(q.id);
        groups.add(
          ListeningQuestionGroup(
            id: q.id,
            questions: [q],
          ),
        );
      }

      // Q1 to Q20 are individual (20 groups)
      for (int i = 1; i <= 20; i++) {
        final g = groups.firstWhere((x) => x.startNumber == i);
        expect(g.questions.length, 1);
        expect(g.rangeLabel, '$i번');
      }

      // Q21 to Q50 are 15 pairs (15 groups)
      for (int i = 21; i <= 49; i += 2) {
        final g = groups.firstWhere((x) => x.startNumber == i);
        expect(g.questions.length, 2);
        expect(g.rangeLabel, '$i~${i + 1}번');
      }

      // Total groups: 20 + 15 = 35 groups
      expect(groups.length, 35);
      final totalQ = groups.fold<int>(0, (sum, g) => sum + g.questions.length);
      expect(totalQ, 50);
    });

    testWidgets('WordLookupSheet renders search results without level badges', (
      tester,
    ) async {
      const mockVocabPage = VocabularyPage(
        items: [
          VocabularyItem(
            id: 'v1',
            word: '약속',
            meaningKo: '다른 사람과 앞으로의 일을 미리 정하여 둠',
            meaningUserLang: 'Appointment',
            level: 2,
            isDownloaded: false,
            isBookmarked: false,
          ),
        ],
        page: 1,
        limit: 10,
        total: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vocabularyRepositoryProvider.overrideWithValue(
              _MockVocabularyRepo(mockVocabPage),
            ),
            grammarRepositoryProvider.overrideWithValue(
              _MockGrammarRepo(const GrammarPage(items: [], page: 1, limit: 5, total: 0)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WordLookupSheet(initialWord: '약속'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('약속'), findsNWidgets(2));
      expect(find.text('다른 사람과 앞으로의 일을 미리 정하여 둠'), findsOneWidget);
      expect(find.text('Appointment'), findsOneWidget);

      // Verify level badge is NOT present
      expect(find.text('2급'), findsNothing);
    });

    testWidgets('SettingsPage renders language setting tile with language display name and opens picker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const profile = UserProfile(
        id: 'u-1',
        email: 'user@test.com',
        nickname: 'Tester',
        role: 'user',
        languageCode: 'en',
        targetLevel: 4,
        timezone: '+09:00',
        fontScale: '1.00',
        timerMode: 'countdown',
        themeColor: 'mint',
        homeLayout: 1,
        practiceLayout: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) async => profile),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );
      await tester.pump();

      // Find language setting tile
      expect(find.text('언어 설정'), findsOneWidget);
      expect(find.text(getLanguageDisplayName('ko')), findsOneWidget);

      // Tap language tile
      await tester.tap(find.text('언어 설정'));
      await tester.pumpAndSettle();

      // Verify bottom sheet language picker opens
      expect(find.text('언어 선택 (Language)'), findsOneWidget);
      expect(find.text("O'zbekcha"), findsOneWidget);
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
    });
  });
}

class _MockVocabularyRepo implements VocabularyRepository {
  final VocabularyPage page;
  _MockVocabularyRepo(this.page);

  @override
  Future<VocabularyPage> getVocabulary(VocabularyQuery query) async => page;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockGrammarRepo implements GrammarRepository {
  final GrammarPage page;
  _MockGrammarRepo(this.page);

  @override
  Future<GrammarPage> getGrammar(GrammarQuery query) async => page;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
