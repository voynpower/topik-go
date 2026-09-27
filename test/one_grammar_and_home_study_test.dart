import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/exam_schedule/data/exam_schedule_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/presentation/grammar_list_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_source_sheet.dart';
import 'package:topik_go/features/home/presentation/home_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

void main() {
  group('OneGrammar & Home Study System Tests', () {
    final mockGrammarList = [
      const GrammarItem(
        id: 'g1',
        pattern: '-(으)ㄹ 뿐만 아니라',
        description: '앞의 사실에 더하여 뒤의 사실도 그러함을 나타냄',
        examples: ['이 옷은 예쁠 뿐만 아니라 가격도 싸요.'],
        tags: ['TOPIK II', '추가'],
        isDownloaded: false,
        isBookmarked: false,
      ),
      const GrammarItem(
        id: 'g2',
        pattern: '-는 바람에',
        description: '부정적인 결과를 가져온 원인이나 이유를 나타냄',
        examples: ['비가 오는 바람에 옷이 다 젖었어요.'],
        tags: ['TOPIK II', '이유'],
        isDownloaded: false,
        isBookmarked: true,
      ),
      const GrammarItem(
        id: 'g3',
        pattern: '-(으)ㄴ/는 반면에',
        description: '두 가지 사실이 서로 대조됨을 나타냄',
        examples: ['도시는 편리한 반면에 복잡해요.'],
        tags: ['TOPIK II', '대조'],
        isDownloaded: false,
        isBookmarked: false,
      ),
      const GrammarItem(
        id: 'g4',
        pattern: '-(으)려고',
        description: '어떤 일을 하려는 의도나 목적을 나타냄',
        examples: ['한국어를 배우려고 한국에 왔어요.'],
        tags: ['TOPIK I', '목적'],
        isDownloaded: false,
        isBookmarked: false,
      ),
    ];

    test('GrammarQuizQuestion generates 4-choice questions with cloze sentences', () {
      final questions = GrammarQuizQuestion.generateQuestions(mockGrammarList, maxQuestions: 4);

      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.options.length, equals(4));
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.options[q.correctIndex], equals(q.targetGrammar.pattern));
        expect(q.clozeSentence, contains('(      )'));
      }
    });

    test('GrammarCategory matches items by keyword category', () {
      final itemReason = mockGrammarList[1]; // -는 바람에
      final itemContrast = mockGrammarList[2]; // -(으)ㄴ/는 반면에
      final itemPurpose = mockGrammarList[3]; // -(으)려고

      expect(GrammarCategory.matches(itemReason, GrammarCategoryType.all), isTrue);
      expect(GrammarCategory.matches(itemReason, GrammarCategoryType.reason), isTrue);
      expect(GrammarCategory.matches(itemContrast, GrammarCategoryType.contrast), isTrue);
      expect(GrammarCategory.matches(itemPurpose, GrammarCategoryType.purpose), isTrue);
    });

    testWidgets('GrammarSourceSheet renders All and Saved options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkedGrammarProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GrammarSourceSheet(mode: GrammarStudyMode.flashcard),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('문법 플래시카드'), findsOneWidget);
      expect(find.textContaining('문법장'), findsWidgets);
      expect(find.textContaining('전체 TOPIK 필수 문법'), findsOneWidget);
    });

    testWidgets('GrammarListPage renders OneGrammar 2 Study Launchers and Category Filter Chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockPage = GrammarPage(
        items: mockGrammarList,
        page: 1,
        limit: 20,
        total: 4,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            grammarProvider.overrideWith((ref, query) async => mockPage),
            bookmarkedGrammarProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: GrammarListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check OneGrammar Hub
      expect(find.text('원그래머 문법 학습'), findsOneWidget);
      expect(find.text('문법 플래시카드'), findsOneWidget);
      expect(find.text('문법 빈칸 퀴즈'), findsOneWidget);

      // Check Category Filter Chips
      expect(find.text('전체'), findsOneWidget);
      expect(find.text('이유·원인'), findsOneWidget);
      expect(find.text('대조·양보'), findsOneWidget);
      expect(find.text('목적·의도'), findsOneWidget);
      expect(find.text('조건·가정'), findsOneWidget);
      expect(find.text('시간·순서'), findsOneWidget);
    });

    testWidgets('HomePage renders Daily Word Challenge, OneVoca 4 Modes, Today Grammar & Quick Practice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockUser = UserProfile(
        id: 'u1',
        email: 'test@topikgo.com',
        nickname: '김토픽',
        role: 'user',
        languageCode: 'ko',
        targetLevel: 5,
        timezone: '+09:00',
        fontScale: '1.00',
        timerMode: 'countdown',
        themeColor: 'mint',
        homeLayout: 1,
        practiceLayout: 1,
      );

      const mockVocabPage = VocabularyPage(
        items: [
          VocabularyItem(
            id: 'v1',
            word: '도전하다',
            meaningKo: '어려운 일이나 기록 경신에 맞서다',
            level: 4,
            isDownloaded: false,
            isBookmarked: false,
          ),
        ],
        page: 1,
        limit: 10,
        total: 1,
      );

      final mockGrammarPage = GrammarPage(
        items: mockGrammarList,
        page: 1,
        limit: 1,
        total: 1,
      );

      const mockBookmarkSummary = BookmarkSummary(
        questions: 5,
        vocabulary: 12,
        grammar: 7,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) async => mockUser),
            vocabularyProvider.overrideWith((ref, query) async => mockVocabPage),
            grammarProvider.overrideWith((ref, query) async => mockGrammarPage),
            examSchedulesProvider.overrideWith((ref) async => []),
            bookmarkSummaryProvider.overrideWith((ref) async => mockBookmarkSummary),
            bookmarkedVocabularyProvider.overrideWith((ref) async => []),
            bookmarkedGrammarProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify User Hero & Streak
      expect(find.textContaining('김토픽'), findsOneWidget);
      expect(find.textContaining('목표: TOPIK II 5급'), findsOneWidget);
      expect(find.textContaining('7일 연속'), findsOneWidget);

      // Verify Daily Word Challenge & 4 Launchers
      expect(find.text('오늘의 단어 챌린지'), findsOneWidget);
      expect(find.text('플래시카드'), findsOneWidget);
      expect(find.text('객관식 퀴즈'), findsOneWidget);
      expect(find.text('받아쓰기'), findsOneWidget);
      expect(find.text('자동재생'), findsOneWidget);

      // Verify Today's Word preview item
      expect(find.text('도전하다'), findsOneWidget);

      // Verify Today's Grammar
      expect(find.text('오늘의 문법'), findsOneWidget);
      expect(find.text('-(으)ㄹ 뿐만 아니라'), findsOneWidget);

      // Verify Quick Practice Buttons
      expect(find.text('실전 연습 바로가기'), findsOneWidget);
      expect(find.text('읽기'), findsOneWidget);
      expect(find.text('듣기'), findsOneWidget);
      expect(find.text('쓰기'), findsOneWidget);

      // Verify Bookmark Summary metrics
      expect(find.text('문제 5개'), findsOneWidget);
      expect(find.text('단어 12개'), findsOneWidget);
      expect(find.text('문법 7개'), findsOneWidget);
    });
  });
}
