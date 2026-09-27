import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/practice/presentation/practice_page.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class _MockUserRepo implements UserRepository {
  @override
  Future<UserProfile> getProfile() async => const UserProfile(
        id: 'test',
        email: 'test@example.com',
        nickname: 'Tester',
        role: 'user',
        languageCode: 'ko',
        targetLevel: 4,
        fontScale: '1.0',
        timezone: '+09:00',
        timerMode: 'countdown',
        themeColor: 'mint',
        homeLayout: 1,
        practiceLayout: 1,
      );

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async => getProfile();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('App Localization reactive switching tests', () {
    test('AppStrings contains full translations for all 9 supported languages', () {
      final supportedCodes = ['ko', 'en', 'uz', 'ru', 'vi', 'zh', 'ja', 'fr', 'de'];
      for (final code in supportedCodes) {
        final strings = AppStrings.of(code);
        expect(strings.locale, code);
        expect(strings.navHome.isNotEmpty, isTrue);
        expect(strings.navPractice.isNotEmpty, isTrue);
        expect(strings.navMockExam.isNotEmpty, isTrue);
        expect(strings.navSettings.isNotEmpty, isTrue);
        expect(strings.readingPractice.isNotEmpty, isTrue);
        expect(strings.listeningPractice.isNotEmpty, isTrue);
        expect(strings.writingPractice.isNotEmpty, isTrue);
        expect(strings.oneVocaTitle.isNotEmpty, isTrue);
        expect(strings.settingsTitle.isNotEmpty, isTrue);
        expect(strings.studyToolsSection.isNotEmpty, isTrue);
        expect(strings.smartWordbook.isNotEmpty, isTrue);
        expect(strings.grammarStudy.isNotEmpty, isTrue);
        expect(strings.tapToViewMeaning.isNotEmpty, isTrue);
        expect(strings.hideTranslation.isNotEmpty, isTrue);
        expect(strings.showTranslation.isNotEmpty, isTrue);
        expect(strings.readingShort.isNotEmpty, isTrue);
        expect(strings.listeningShort.isNotEmpty, isTrue);
        expect(strings.writingShort.isNotEmpty, isTrue);
        expect(strings.allGroups.isNotEmpty, isTrue);
        expect(strings.addNewWord.isNotEmpty, isTrue);
        expect(strings.streakConsecutive.isNotEmpty, isTrue);
        expect(strings.streakTotal.isNotEmpty, isTrue);
        expect(strings.dailyStudyGoalTitle.isNotEmpty, isTrue);
        expect(strings.levelUnit.isNotEmpty, isTrue);
        expect(strings.reviewHardWords.isNotEmpty, isTrue);
        expect(strings.reviewSavedWords.isNotEmpty, isTrue);
      }

      // Assert Uzbek specific refinements
      final uz = AppStrings.of('uz');
      expect(uz.dictation, 'Diktant');
      expect(uz.quiz, 'Test');
      expect(uz.flashcard, 'Kartochkalar');
      expect(uz.autoplay, 'Avto-ijro');
      expect(uz.studyRecord, 'O‘rganish tarixi');
      expect(uz.statusUnsure, 'O‘rganilmoqda');
      expect(uz.readingShort, "O'qish");
      expect(uz.listeningShort, 'Tinglash');
      expect(uz.writingShort, 'Yozish');
    });

    test('appStringsProvider reactively updates when currentLanguageProvider changes', () async {
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(_MockUserRepo()),
        ],
      );

      try {
        // Initial default is Korean ('ko')
        expect(container.read(appStringsProvider).locale, 'ko');
        expect(container.read(appStringsProvider).navHome, '홈');
        expect(container.read(appStringsProvider).smartWordbook, '스마트 단어장');

        // Switch to English ('en')
        await container.read(currentLanguageProvider.notifier).setLanguage('en');
        expect(container.read(appStringsProvider).locale, 'en');
        expect(container.read(appStringsProvider).navHome, 'Home');
        expect(container.read(appStringsProvider).smartWordbook, 'Smart Wordbook');

        // Switch to Uzbek ('uz')
        await container.read(currentLanguageProvider.notifier).setLanguage('uz');
        expect(container.read(appStringsProvider).locale, 'uz');
        expect(container.read(appStringsProvider).navHome, 'Bosh sahifa');
        expect(container.read(appStringsProvider).smartWordbook, "Aqlli lug'at");

        // Switch to Russian ('ru')
        await container.read(currentLanguageProvider.notifier).setLanguage('ru');
        expect(container.read(appStringsProvider).locale, 'ru');
        expect(container.read(appStringsProvider).navHome, 'Главная');
        expect(container.read(appStringsProvider).smartWordbook, 'Умный словарь');

        // Switch to Vietnamese ('vi')
        await container.read(currentLanguageProvider.notifier).setLanguage('vi');
        expect(container.read(appStringsProvider).locale, 'vi');
        expect(container.read(appStringsProvider).navHome, 'Trang chủ');

        // Switch to Chinese ('zh')
        await container.read(currentLanguageProvider.notifier).setLanguage('zh');
        expect(container.read(appStringsProvider).locale, 'zh');
        expect(container.read(appStringsProvider).navHome, '首页');

        // Switch to Japanese ('ja')
        await container.read(currentLanguageProvider.notifier).setLanguage('ja');
        expect(container.read(appStringsProvider).locale, 'ja');
        expect(container.read(appStringsProvider).navHome, 'ホーム');
      } finally {
        container.dispose();
      }
    });

    testWidgets('PracticePage reactively switches non-exam chrome to the selected language', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(_MockUserRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PracticePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default Korean ('ko')
      expect(find.text('유형별 문제 풀기'), findsOneWidget);
      expect(find.text('TOPIK II 읽기 연습'), findsOneWidget);

      // Switch to English ('en')
      await container.read(currentLanguageProvider.notifier).setLanguage('en');
      await tester.pumpAndSettle();

      expect(find.text('Practice by Section'), findsOneWidget);
      expect(find.text('Reading Practice'), findsOneWidget);

      // Switch to Uzbek ('uz')
      await container.read(currentLanguageProvider.notifier).setLanguage('uz');
      await tester.pumpAndSettle();

      expect(find.text("Bo'limlar bo'yicha mashq qilish"), findsOneWidget);
      expect(find.text("O'qish mashqi"), findsOneWidget);
    });

    testWidgets('SettingsPage reactively switches headers and tiles to the selected language', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(_MockUserRepo()),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'test-user',
              email: 'tester@example.com',
              nickname: 'Tester',
              role: 'user',
              languageCode: 'ko',
              targetLevel: 4,
              fontScale: '1.00',
              timezone: '+09:00',
              timerMode: 'countdown',
              themeColor: 'mint',
              homeLayout: 1,
              practiceLayout: 1,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default Korean ('ko')
      expect(find.text('설정'), findsWidgets);
      expect(find.text('일반 설정'), findsOneWidget);
      expect(find.text('언어 설정'), findsOneWidget);

      // Switch to English ('en')
      await container.read(currentLanguageProvider.notifier).setLanguage('en');
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      // Switch to Uzbek ('uz')
      await container.read(currentLanguageProvider.notifier).setLanguage('uz');
      await tester.pumpAndSettle();

      expect(find.text('Sozlamalar'), findsWidgets);
      expect(find.text('Umumiy sozlamalar'), findsOneWidget);
      expect(find.text('Til sozlamasi'), findsOneWidget);
    });
  });
}
