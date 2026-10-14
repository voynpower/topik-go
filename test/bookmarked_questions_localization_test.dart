import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/bookmarks/presentation/bookmarked_questions_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BookmarkedQuestionsPage empty state localization tests', () {
    testWidgets('displays Korean empty description when locale is ko', (
      tester,
    ) async {
      final strings = AppStrings.of('ko');
      final container = ProviderContainer(
        overrides: [
          appStringsProvider.overrideWithValue(strings),
          bookmarkedQuestionsProvider.overrideWith(
            (ref) async => <BookmarkedQuestion>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BookmarkedQuestionsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.bookmarkedQuestionsEmptyDesc), findsOneWidget);
      expect(
        find.text(
          '연습이나 모의고사에서 헷갈리는 문제를 저장해두고 시험 전에 집중 복습해 보세요.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays English empty description when locale is en', (
      tester,
    ) async {
      final strings = AppStrings.of('en');
      final container = ProviderContainer(
        overrides: [
          appStringsProvider.overrideWithValue(strings),
          bookmarkedQuestionsProvider.overrideWith(
            (ref) async => <BookmarkedQuestion>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BookmarkedQuestionsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.bookmarkedQuestionsEmptyDesc), findsOneWidget);
      expect(
        find.text(
          'Save confusing questions from practice or mock exams and review them intensively before the test.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays Uzbek empty description when locale is uz', (
      tester,
    ) async {
      final strings = AppStrings.of('uz');
      final container = ProviderContainer(
        overrides: [
          appStringsProvider.overrideWithValue(strings),
          bookmarkedQuestionsProvider.overrideWith(
            (ref) async => <BookmarkedQuestion>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BookmarkedQuestionsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.bookmarkedQuestionsEmptyDesc), findsOneWidget);
      expect(
        find.text(
          "Mashq yoki soxta imtihonlarda chalkash savollarni saqlab qoling va testdan oldin ularni chuqur takrorlang.",
        ),
        findsOneWidget,
      );
    });
  });
}
