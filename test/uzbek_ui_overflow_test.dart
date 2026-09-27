import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/exam_schedule/data/exam_schedule_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/presentation/grammar_flashcard_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_quiz_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_source_sheet.dart';
import 'package:topik_go/features/home/presentation/home_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'app_language': 'uz'});
  });

  group('Uzbek UI & Layout Overflow Verification Tests', () {
    testWidgets('Home page bottom bookmarks panel and exam card render without overflow in Uzbek on 360px screen', (tester) async {
      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final uzStrings = AppStrings.of('uz');
      final testSchedule = TopikExamSchedule(
        id: 'test_102',
        title: 'TOPIK II 102-son',
        examDate: DateTime.now().add(const Duration(days: 14)),
        dDayLabel: 'D-14',
        location: 'Toshkent, O‘zbekiston',
        registrationPeriodLabel: '2026.08.01 ~ 2026.08.10',
        resultDateLabel: '2026.11.20',
        feeLabel: '55,000 KRW',
      );

      const mockUser = UserProfile(
        id: 'u1',
        email: 'test@topikgo.com',
        nickname: 'Aziz',
        role: 'user',
        languageCode: 'uz',
        targetLevel: 5,
        timezone: '+05:00',
        fontScale: '1.00',
        timerMode: 'countdown',
        themeColor: 'mint',
        homeLayout: 1,
        practiceLayout: 1,
      );

      const mockBookmarkSummary = BookmarkSummary(
        questions: 0,
        vocabulary: 0,
        grammar: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStringsProvider.overrideWithValue(uzStrings),
            userProfileProvider.overrideWith((ref) async => mockUser),
            vocabularyProvider.overrideWith((ref, query) async => const VocabularyPage(
                  items: [],
                  page: 1,
                  limit: 10,
                  total: 0,
                )),
            grammarProvider.overrideWith((ref, query) async => const GrammarPage(
                  items: [],
                  page: 1,
                  limit: 1,
                  total: 0,
                )),
            examSchedulesProvider.overrideWith((ref) async => [testSchedule]),
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

      // Check NextExamCard localized labels in Uzbek
      expect(find.textContaining('Imtihon sanasi:'), findsOneWidget);
      expect(find.textContaining('Qabul muddati:'), findsOneWidget);
      expect(find.textContaining('Natijalar eʼloni:'), findsOneWidget);
      expect(find.textContaining('Imtihon to‘lovi:'), findsOneWidget);
      expect(find.text('D-14'), findsOneWidget);

      // Check Bookmarks summary pills in Uzbek
      expect(find.text('0 ta savol'), findsOneWidget);
      expect(find.text("0 ta so'z"), findsOneWidget);
      // Zero RenderFlex overflow caught!
      expect(tester.takeException(), isNull);
    });

    testWidgets('GrammarSourceSheet renders pure grammar titles without vocabulary (lugat) leakage in Uzbek', (tester) async {
      final uzStrings = AppStrings.of('uz');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStringsProvider.overrideWithValue(uzStrings),
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

      // Verify that grammar terms are used, NOT vocabulary ("lug'at")
      expect(find.text('Saqlangan grammatika'), findsOneWidget);
      expect(find.text('Barcha TOPIK asosiy grammatikasi'), findsOneWidget);
      expect(find.textContaining('lug‘atim'), findsNothing);
      expect(find.textContaining("lug'at"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GrammarFlashcardPage action buttons and dialog render without overflow in Uzbek', (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final uzStrings = AppStrings.of('uz');
      const mockItem = GrammarItem(
        id: 'g_1',
        pattern: '-기 때문에',
        description: 'Sabab yoki asosni bildiradi.',
        tags: ['Sabab'],
        examples: ['비가 오기 때문에 우산을 썼어요.'],
        isDownloaded: false,
        isBookmarked: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStringsProvider.overrideWithValue(uzStrings),
            studyGrammarProvider(const GrammarStudySource.all()).overrideWith(
              (ref) async => [mockItem],
            ),
          ],
          child: const MaterialApp(
            home: GrammarFlashcardPage(source: GrammarStudySource.all()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Qaytarish kerak'), findsOneWidget);
      expect(find.text('Yodladim'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GrammarQuizPage renders localized prompt and options without hardcoded Korean in Uzbek', (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final uzStrings = AppStrings.of('uz');
      final mockItems = <GrammarItem>[
        const GrammarItem(
          id: 'g_1',
          pattern: '-기 때문에',
          description: 'Sababni bildiradi.',
          tags: ['Sabab'],
          examples: ['비가 오기 때문에 길이 미끄럽습니다.'],
          isDownloaded: false,
          isBookmarked: false,
        ),
        const GrammarItem(
          id: 'g_2',
          pattern: '-(으)려고',
          description: 'Maqsadni bildiradi.',
          tags: ['Maqsad'],
          examples: ['한국어를 배우려고 공부합니다.'],
          isDownloaded: false,
          isBookmarked: false,
        ),
        const GrammarItem(
          id: 'g_3',
          pattern: '-(으)ㄹ 뿐만 아니라',
          description: 'Qo‘shimcha maʼnoni bildiradi.',
          tags: ['Qo‘shimcha'],
          examples: ['한국어는 재미있을 뿐만 아니라 유용해요.'],
          isDownloaded: false,
          isBookmarked: false,
        ),
        const GrammarItem(
          id: 'g_4',
          pattern: '-(으)ㄴ/는 반면에',
          description: 'Taqqoslashni bildiradi.',
          tags: ['Taqqoslash'],
          examples: ['낮에는 더운 반면에 밤에는 쌀쌀해요.'],
          isDownloaded: false,
          isBookmarked: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStringsProvider.overrideWithValue(uzStrings),
            studyGrammarProvider(const GrammarStudySource.all()).overrideWith(
              (ref) async => mockItems,
            ),
          ],
          child: const MaterialApp(
            home: GrammarQuizPage(source: GrammarStudySource.all()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bo‘sh joyga mos grammatik ifodani tanlang.'), findsOneWidget);
      expect(find.text('다음 빈칸에 알맞은 문법 표현을 고르십시오.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
