import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/exam_schedule/data/exam_schedule_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';
import 'package:topik_go/features/home/presentation/home_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

void main() {
  group("Today's Grammar Home Translation Tests", () {
    const mockUser = UserProfile(
      id: 'u1',
      email: 'test@example.com',
      nickname: '토픽러',
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

    const testGrammarItem = GrammarItem(
      id: 'g_go_itda',
      pattern: '-고 있다',
      description: '어떤 동작이 현재 계속 진행되고 있음을 나타냄',
      meaningKo: '어떤 동작이 현재 계속 진행되고 있음을 나타냄',
      meaningUz: 'Harakat ayni damda davom etayotganini bildiradi (davomli zamon)',
      meaningRu: 'Выражает действие, происходящее в данный момент (настоящее длительное)',
      meaningEn: 'Expresses an action currently in progress (-ing)',
      examples: [
        '지금 도서관에서 한국어 시험공부를 하고 있어요.',
      ],
      richExamples: [
        MasterGrammarExample(
          korean: '지금 도서관에서 한국어 시험공부를 하고 있어요.',
          uzbek: 'Hozir kutubxonada koreys tili imtihoniga tayyorlanyapman.',
          russian: 'Сейчас в библиотеке готовлюсь к экзамену по корейскому языку.',
          english: 'I am currently studying for the Korean exam at the library.',
          tag: '기본 회화',
        ),
      ],
      tags: ['시간·순서', 'TOPIK I'],
      isDownloaded: false,
      isBookmarked: false,
      category: '시간·순서',
    );

    final mockGrammarPage = const GrammarPage(
      items: [testGrammarItem],
      page: 1,
      limit: 1,
      total: 1,
    );

    const mockBookmarkSummary = BookmarkSummary(
      questions: 0,
      vocabulary: 0,
      grammar: 0,
    );

    const emptyVocabPage = VocabularyPage(
      items: [],
      page: 1,
      limit: 1,
      total: 0,
    );

    testWidgets('Today Grammar displays Uzbek meaning and Uzbek translation when language is uz', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'preferred_language_code': 'uz'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('uz')),
            appStringsProvider.overrideWithValue(AppStrings.of('uz')),
            userProfileProvider.overrideWith((ref) async => mockUser),
            grammarProvider.overrideWith((ref, query) async => mockGrammarPage),
            vocabularyProvider.overrideWith((ref, query) async => emptyVocabPage),
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

      // Meaning should be in Uzbek
      expect(find.text('Harakat ayni damda davom etayotganini bildiradi (davomli zamon)'), findsOneWidget);

      // Korean example sentence
      expect(find.text('지금 도서관에서 한국어 시험공부를 하고 있어요.'), findsOneWidget);

      // Uzbek translation of the example
      expect(find.text('Hozir kutubxonada koreys tili imtihoniga tayyorlanyapman.'), findsOneWidget);

      // Russian and English translations should NOT leak into the UI
      expect(find.textContaining('Сейчас в библиотеке'), findsNothing);
      expect(find.textContaining('I am currently studying'), findsNothing);
    });

    testWidgets('Today Grammar displays English meaning and English translation when language is en', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'preferred_language_code': 'en'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('en')),
            appStringsProvider.overrideWithValue(AppStrings.of('en')),
            userProfileProvider.overrideWith((ref) async => mockUser),
            grammarProvider.overrideWith((ref, query) async => mockGrammarPage),
            vocabularyProvider.overrideWith((ref, query) async => emptyVocabPage),
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

      // Meaning should be in English
      expect(find.text('Expresses an action currently in progress (-ing)'), findsOneWidget);

      // Korean example sentence
      expect(find.text('지금 도서관에서 한국어 시험공부를 하고 있어요.'), findsOneWidget);

      // English translation of the example
      expect(find.text('I am currently studying for the Korean exam at the library.'), findsOneWidget);

      // Uzbek and Russian translations should NOT appear
      expect(find.textContaining('Hozir kutubxonada'), findsNothing);
      expect(find.textContaining('Сейчас в библиотеке'), findsNothing);
    });

    testWidgets('Today Grammar displays Russian meaning and Russian translation when language is ru', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'preferred_language_code': 'ru'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ru')),
            appStringsProvider.overrideWithValue(AppStrings.of('ru')),
            userProfileProvider.overrideWith((ref) async => mockUser),
            grammarProvider.overrideWith((ref, query) async => mockGrammarPage),
            vocabularyProvider.overrideWith((ref, query) async => emptyVocabPage),
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

      // Meaning should be in Russian
      expect(find.text('Выражает действие, происходящее в данный момент (настоящее длительное)'), findsOneWidget);

      // Korean example sentence
      expect(find.text('지금 도서관에서 한국어 시험공부를 하고 있어요.'), findsOneWidget);

      // Russian translation of the example
      expect(find.text('Сейчас в библиотеке готовлюсь к экзамену по корейскому языку.'), findsOneWidget);

      // Uzbek and English translations should NOT appear
      expect(find.textContaining('Hozir kutubxonada'), findsNothing);
      expect(find.textContaining('I am currently studying'), findsNothing);
    });

    testWidgets('Today Grammar displays Korean meaning and no redundant foreign translation when language is ko', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({'preferred_language_code': 'ko'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
            appStringsProvider.overrideWithValue(AppStrings.of('ko')),
            userProfileProvider.overrideWith((ref) async => mockUser),
            grammarProvider.overrideWith((ref, query) async => mockGrammarPage),
            vocabularyProvider.overrideWith((ref, query) async => emptyVocabPage),
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

      // Meaning should be in Korean
      expect(find.text('어떤 동작이 현재 계속 진행되고 있음을 나타냄'), findsOneWidget);

      // Korean example sentence
      expect(find.text('지금 도서관에서 한국어 시험공부를 하고 있어요.'), findsOneWidget);

      // No foreign translations should appear
      expect(find.textContaining('Hozir kutubxonada'), findsNothing);
      expect(find.textContaining('Сейчас в библиотеке'), findsNothing);
      expect(find.textContaining('I am currently studying'), findsNothing);
    });
  });
}

class _StaticLanguageNotifier extends LanguageNotifier {
  _StaticLanguageNotifier(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}
