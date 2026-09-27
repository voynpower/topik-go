import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart' as repo;
import 'package:topik_go/features/vocabulary/domain/ai_sentence_service.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_mastery_service.dart';
import 'package:topik_go/features/vocabulary/presentation/pages/voca_list_tab_view.dart';
import 'package:topik_go/features/vocabulary/presentation/pages/voca_study_hub_tab_view.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_page.dart';
import 'package:topik_go/features/vocabulary/presentation/widgets/voca_word_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TopikVoca AI Sentence & Mastery Tests', () {
    test('AiSentenceService returns dynamic examples and cycles variations', () async {
      final ex0 = await AiSentenceService.getExample(
        word: '가꾸다',
        index: 0,
        targetLang: 'ko',
      );
      expect(ex0.korean, contains('가꾸다'));
      expect(ex0.contextTag, equals('일상 대화'));

      final ex1 = await AiSentenceService.getExample(
        word: '가꾸다',
        index: 1,
        targetLang: 'ko',
      );
      expect(ex1.korean, contains('가꾸다'));
      expect(ex1.korean, isNot(equals(ex0.korean)));
    });

    test('WordMasteryNotifier defaults to hard and cycles statuses properly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(wordMasteryProvider.notifier);
      expect(notifier.getStatus('v1'), equals(WordMasteryStatus.hard));

      await notifier.cycleStatus('v1');
      expect(notifier.getStatus('v1'), equals(WordMasteryStatus.unsure));

      await notifier.cycleStatus('v1');
      expect(notifier.getStatus('v1'), equals(WordMasteryStatus.mastered));

      await notifier.cycleStatus('v1');
      expect(notifier.getStatus('v1'), equals(WordMasteryStatus.hard));

      await notifier.setStatus('v1', WordMasteryStatus.mastered);
      expect(notifier.getStatus('v1'), equals(WordMasteryStatus.mastered));
    });

    testWidgets('VocaWordCard renders word and expands to show AI example sentence', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const sampleWord = repo.VocabularyItem(
        id: 'v100',
        word: '노력하다',
        meaningKo: '목적을 이루기 위하여 힘을 쓰다',
        level: 3,
        isDownloaded: false,
        isBookmarked: false,
      );

      final strings = AppStrings.of('ko');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VocaWordCard(
                item: sampleWord,
                strings: strings,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Word should be displayed, but meaning is hidden by default (문제 2)
      expect(find.text('노력하다'), findsOneWidget);
      expect(find.text('목적을 이루기 위하여 힘을 쓰다'), findsNothing);
      expect(find.text('탭하여 뜻 보기'), findsOneWidget);

      // AI example is also hidden initially (문제 3)
      expect(find.text(strings.aiExample), findsNothing);

      // Tap word to reveal translation (문제 2)
      await tester.tap(find.text('노력하다'));
      await tester.pumpAndSettle();

      // Now meaning is visible, but AI example is still hidden
      expect(find.text('목적을 이루기 위하여 힘을 쓰다'), findsOneWidget);
      expect(find.text(strings.aiExample), findsNothing);

      // Tap AI icon button to reveal AI example (문제 3)
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      // AI example card and refresh button should now be visible
      expect(find.text(strings.aiExample), findsOneWidget);
      expect(find.text(strings.seeOtherExamples), findsOneWidget);

      // Tap [다른 예문 보기 🔄] button to cycle variation
      await tester.tap(find.text(strings.seeOtherExamples));
      await tester.pumpAndSettle();
      expect(find.text(strings.aiExample), findsOneWidget);
    });

    testWidgets('VocabularyPage top segmented TabBar switches between Wordbook and Study Hub', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockPage = repo.VocabularyPage(
        items: [
          repo.VocabularyItem(
            id: 'v1',
            word: '성공하다',
            meaningKo: '목적한 바를 이루다',
            level: 3,
            isDownloaded: false,
            isBookmarked: false,
          ),
        ],
        page: 1,
        limit: 20,
        total: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repo.vocabularyProvider.overrideWith((ref, query) async => mockPage),
            bookmarkedVocabularyProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: VocabularyPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings.of('ko');

      // Check segmented tab bar items
      expect(find.text(strings.tabWordbook), findsWidgets);
      expect(find.text(strings.tabStudyHub), findsOneWidget);

      // Initial tab is Wordbook (VocaListTabView)
      expect(find.byType(VocaListTabView), findsOneWidget);
      expect(find.text('성공하다'), findsOneWidget);

      // Tap on Study tab
      await tester.tap(find.text(strings.tabStudyHub));
      await tester.pumpAndSettle();

      // Study Hub tab view should now be active
      expect(find.byType(VocaStudyHubTabView), findsOneWidget);
      expect(find.text(strings.studyRecord), findsOneWidget);
      expect(find.text(strings.flashcard), findsOneWidget);
      expect(find.text(strings.quiz), findsOneWidget);
      expect(find.text(strings.dictation), findsOneWidget);
      expect(find.text(strings.autoplay), findsOneWidget);
    });

    testWidgets('VocaWordCard has 3-dots popup menu (Edit and Delete) and no TOPIK level badge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const sampleWord = repo.VocabularyItem(
        id: 'v101',
        word: '포기하다',
        meaningKo: '하던 일을 중도에 그만두다',
        level: 3,
        isDownloaded: false,
        isBookmarked: false,
      );

      final strings = AppStrings.of('ko');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VocaWordCard(
                item: sampleWord,
                strings: strings,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // TOPIK level badge is removed
      expect(find.text('TOPIK 3급'), findsNothing);

      // 3-dots menu button is present
      final moreButton = find.byIcon(Icons.more_vert);
      expect(moreButton, findsOneWidget);

      // Open popup menu
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Check Edit and Delete items in popup menu
      expect(find.text(strings.edit), findsOneWidget);
      expect(find.text(strings.delete), findsOneWidget);

      // Tap Edit
      await tester.tap(find.text(strings.edit));
      await tester.pumpAndSettle();

      // Bottom sheet for edit is shown with word and meaning
      expect(find.text('포기하다'), findsWidgets);
      expect(find.text('하던 일을 중도에 그만두다'), findsWidgets);
      expect(find.text(strings.save), findsOneWidget);

      // Change word and meaning text in edit modal
      await tester.enterText(find.widgetWithText(TextField, '한국어 단어'), '포기하지마');
      await tester.enterText(find.widgetWithText(TextField, '단어 뜻'), '절대 포기하지 마라');
      await tester.tap(find.text(strings.save));
      await tester.pumpAndSettle();

      // Card now displays edited word
      expect(find.text('포기하지마'), findsOneWidget);

      // Open popup menu to test Delete
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text(strings.delete));
      await tester.pumpAndSettle();

      // Delete confirmation dialog is shown
      expect(find.textContaining(strings.deleteConfirm), findsOneWidget);

      // Confirm delete (FilledButton with strings.delete)
      await tester.tap(find.widgetWithText(FilledButton, strings.delete));
      await tester.pumpAndSettle();

      // Word is deleted and collapsed/gone
      expect(find.text('포기하지마'), findsNothing);
    });

    testWidgets('VocaListTabView does not show TOPIK level classification dropdown', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockPage = repo.VocabularyPage(
        items: [
          repo.VocabularyItem(
            id: 'v1',
            word: '시작하다',
            meaningKo: '어떤 일이나 행동의 첫 단계를 떼다',
            level: 3,
            isDownloaded: false,
            isBookmarked: false,
          ),
        ],
        page: 1,
        limit: 20,
        total: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repo.vocabularyProvider.overrideWith((ref, query) async => mockPage),
            bookmarkedVocabularyProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: VocaListTabView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // TOPIK level classification dropdown should NOT exist
      expect(find.textContaining('TOPIK I (1·2'), findsNothing);
      expect(find.textContaining('TOPIK II 3'), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    testWidgets('VocaListTabView deletes a word and removes it from the list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockPage = repo.VocabularyPage(
        items: [
          repo.VocabularyItem(
            id: 'v10',
            word: '공부하다',
            meaningKo: '학문이나 기술을 배우고 익히다',
            level: 3,
            isDownloaded: false,
            isBookmarked: false,
          ),
          repo.VocabularyItem(
            id: 'v20',
            word: '운동하다',
            meaningKo: '몸을 움직여 운동을 하다',
            level: 3,
            isDownloaded: false,
            isBookmarked: false,
          ),
        ],
        page: 1,
        limit: 20,
        total: 2,
      );

      final strings = AppStrings.of('ko');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repo.vocabularyProvider.overrideWith((ref, query) async => mockPage),
            bookmarkedVocabularyProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: VocaListTabView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('공부하다'), findsOneWidget);
      expect(find.text('운동하다'), findsOneWidget);

      // Tap 3 dots on the first word
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text(strings.delete));
      await tester.pumpAndSettle();

      // Confirm delete dialog
      await tester.tap(find.widgetWithText(FilledButton, strings.delete));
      await tester.pumpAndSettle();

      // '공부하다' should be removed, while '운동하다' remains
      expect(find.text('공부하다'), findsNothing);
      expect(find.text('운동하다'), findsOneWidget);
    });
  });
}
