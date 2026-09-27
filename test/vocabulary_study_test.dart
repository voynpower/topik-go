import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/presentation/grammar_list_page.dart';
import 'package:topik_go/features/practice/presentation/practice_page.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_list_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_source_sheet.dart';

void main() {
  group('OneVoca Vocabulary Learning Tests', () {
    test('HangulHelper extracts initial consonants correctly', () {
      expect(HangulHelper.getInitials('한국어'), equals('ㅎㄱㅇ'));
      expect(HangulHelper.getInitials('사자성어'), equals('ㅅㅈㅅㅇ'));
      expect(HangulHelper.getInitials('가져오다'), equals('ㄱㅈㅇㄷ'));
      expect(HangulHelper.getInitials('TOPIK 시험'), equals('TOPIK ㅅㅎ'));
    });

    test('HangulHelper verifies spelling match correctly', () {
      expect(HangulHelper.isSpellingMatch('한국어', '한국어'), isTrue);
      expect(HangulHelper.isSpellingMatch('한국어 ', '한국어'), isTrue);
      expect(HangulHelper.isSpellingMatch('사자 성어', '사자성어'), isTrue);
      expect(HangulHelper.isSpellingMatch('한국어!', '한국어'), isTrue);
      expect(HangulHelper.isSpellingMatch('중국어', '한국어'), isFalse);
    });

    test('VocabularyQuizQuestion generates valid 4-choice questions', () {
      final sampleWords = [
        const VocabularyItem(
          id: 'v1',
          word: '성공하다',
          meaningKo: '목적한 바를 이루다',
          level: 3,
          isDownloaded: false,
          isBookmarked: false,
        ),
        const VocabularyItem(
          id: 'v2',
          word: '실패하다',
          meaningKo: '일을 잘못하여 뜻한 대로 되지 않다',
          level: 3,
          isDownloaded: false,
          isBookmarked: false,
        ),
        const VocabularyItem(
          id: 'v3',
          word: '노력하다',
          meaningKo: '목적을 이루기 위하여 힘을 쓰다',
          level: 3,
          isDownloaded: false,
          isBookmarked: false,
        ),
        const VocabularyItem(
          id: 'v4',
          word: '도전하다',
          meaningKo: '정면으로 맞서 싸움을 돋우다',
          level: 3,
          isDownloaded: false,
          isBookmarked: false,
        ),
        const VocabularyItem(
          id: 'v5',
          word: '극복하다',
          meaningKo: '악조건이나 고생을 이겨 내다',
          level: 4,
          isDownloaded: false,
          isBookmarked: false,
        ),
      ];

      final questions = VocabularyQuizQuestion.generateQuestions(sampleWords, maxQuestions: 5);
      expect(questions.length, equals(5));

      for (final q in questions) {
        expect(q.options.length, equals(4));
        expect(q.correctIndex, inInclusiveRange(0, 3));
        final expectedAnswer = q.isWordToMeaning ? q.targetWord.meaningKo : q.targetWord.word;
        expect(q.options[q.correctIndex], equals(expectedAnswer));
      }
    });

    testWidgets('PracticePage removes explanation video and features smart wordbook', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PracticePage(),
          ),
        ),
      );
      await tester.pump();

      // Verify "문제 해설 영상" is completely removed
      expect(find.text('문제 해설 영상'), findsNothing);

      // Verify "스마트 단어장" tile exists with OneVoca badges
      expect(find.text('스마트 단어장'), findsOneWidget);
      expect(find.text('원보카 4대 암기 (플래시카드 · 퀴즈 · 받아쓰기 · 자동재생)'), findsOneWidget);

      // Verify "문법 공부" tile exists as reference
      expect(find.text('문법 공부'), findsOneWidget);
    });

    testWidgets('VocabularyListPage renders OneVoca 4 study mode launchers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockPage = VocabularyPage(
        items: [
          VocabularyItem(
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
            vocabularyProvider.overrideWith((ref, query) async => mockPage),
            bookmarkedVocabularyProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: VocabularyListPage(),
          ),
        ),
      );
      await tester.pump();

      // Check for OneVoca hub title and 4 mode launchers
      expect(find.text('스마트 단어장'), findsOneWidget);
      expect(find.text('원보카 4대 암기 모드'), findsOneWidget);
      expect(find.text('플래시카드'), findsOneWidget);
      expect(find.text('객관식 퀴즈'), findsOneWidget);
      expect(find.text('받아쓰기'), findsOneWidget);
      expect(find.text('자동재생'), findsOneWidget);

      // Check level filter chips
      expect(find.text('전체'), findsOneWidget);
      expect(find.text('★ 내 저장 단어'), findsOneWidget);

      // Verify level chips (1~6급) and level badge (3급) are NOT rendered
      expect(find.text('1급'), findsNothing);
      expect(find.text('2급'), findsNothing);
      expect(find.text('3급'), findsNothing);
      expect(find.text('4급'), findsNothing);
      expect(find.text('5급'), findsNothing);
      expect(find.text('6급'), findsNothing);
    });

    testWidgets('GrammarListPage renders without level chips or level badges', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const mockGrammarPage = GrammarPage(
        items: [
          GrammarItem(
            id: 'g1',
            pattern: '-기 때문에',
            description: '이유나 원인을 나타냄',
            examples: ['비가 오기 때문에 우산을 썼어요.'],
            tags: ['이유', '원인'],
            level: 2,
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
            grammarProvider.overrideWith((ref, query) async => mockGrammarPage),
          ],
          child: const MaterialApp(
            home: GrammarListPage(),
          ),
        ),
      );
      await tester.pump();

      // Check title and pattern
      expect(find.text('문법 공부'), findsOneWidget);
      expect(find.text('-기 때문에'), findsOneWidget);

      // Verify level chips and level badges are NOT rendered
      expect(find.text('1급'), findsNothing);
      expect(find.text('2급'), findsNothing);
      expect(find.text('3급'), findsNothing);
    });

    test('TranslationService supported languages and display names', () {
      expect(kSupportedLanguages.length, equals(9));
      final codes = kSupportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['ko', 'en', 'uz', 'ru', 'vi', 'zh', 'ja', 'fr', 'de']));

      expect(getLanguageDisplayName('ko'), equals('한국어 (Korean)'));
      expect(getLanguageDisplayName('en'), equals('English (English)'));
      expect(getLanguageDisplayName('uz'), equals("O'zbekcha (Uzbek)"));
      expect(getLanguageDisplayName('ru'), equals('Русский (Russian)'));
    });

    testWidgets('VocabularySourceSheet provides All TOPIK and Saved word options without level chips', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkedVocabularyProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: VocabularySourceSheet(mode: VocabularyStudyMode.flashcard),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('내 저장 단어장'), findsOneWidget);
      expect(find.text('전체 TOPIK 필수 어휘'), findsOneWidget);
      expect(find.text('또는 TOPIK 급수별 필수 단어 선택'), findsNothing);
      expect(find.text('3급'), findsNothing);
    });
  });
}
