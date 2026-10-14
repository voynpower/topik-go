import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/bookmarks/presentation/bookmarked_grammar_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BookmarkedGrammarPage Empty State Tests', () {
    testWidgets('renders icon, title, desc, and action button when empty', (
      tester,
    ) async {
      final strings = AppStrings.of('ko');
      bool navigatedToGrammar = false;

      final router = GoRouter(
        initialLocation: '/bookmarks/grammar',
        routes: [
          GoRoute(
            path: '/bookmarks/grammar',
            builder: (context, state) => const BookmarkedGrammarPage(),
          ),
          GoRoute(
            path: '/grammar',
            builder: (context, state) {
              navigatedToGrammar = true;
              return const Scaffold(body: Text('Grammar Hub'));
            },
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appStringsProvider.overrideWithValue(strings),
          bookmarkedGrammarProvider.overrideWith(
            (ref) async => <BookmarkedGrammar>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Icon
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

      // Verify Title
      expect(find.text(strings.noBookmarks), findsOneWidget);

      // Verify Description
      expect(find.text(strings.mySavedGrammarbookDesc), findsOneWidget);

      // Verify Button
      final buttonFinder = find.widgetWithText(FilledButton, strings.allTopikGrammar);
      expect(buttonFinder, findsOneWidget);

      // Tap button and verify navigation
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(navigatedToGrammar, isTrue);
    });
  });
}
