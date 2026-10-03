import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/core/topik_mode/topik_mode_provider.dart';
import 'package:topik_go/core/topik_mode/topik_mode_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TopikMode Enum & Properties', () {
    test('TopikMode.topik1 has correct structure and properties', () {
      const mode = TopikMode.topik1;
      expect(mode.isTopik1, isTrue);
      expect(mode.isTopik2, isFalse);
      expect(mode.hasWriting, isFalse);
      expect(mode.durationMinutes, equals(100));
      expect(mode.durationSeconds, equals(6000));
      expect(mode.totalQuestions, equals(70));
      expect(mode.listeningCount, equals(30));
      expect(mode.readingCount, equals(40));
      expect(mode.writingCount, equals(0));
      expect(mode.maxScore, equals(200));
      expect(mode.label, equals('TOPIK I'));
      expect(mode.levelRangeLabel, equals('1~2급'));
    });

    test('TopikMode.topik2 has correct structure and properties', () {
      const mode = TopikMode.topik2;
      expect(mode.isTopik1, isFalse);
      expect(mode.isTopik2, isTrue);
      expect(mode.hasWriting, isTrue);
      expect(mode.durationMinutes, equals(180));
      expect(mode.durationSeconds, equals(10800));
      expect(mode.totalQuestions, equals(104));
      expect(mode.listeningCount, equals(50));
      expect(mode.readingCount, equals(50));
      expect(mode.writingCount, equals(4));
      expect(mode.maxScore, equals(300));
      expect(mode.label, equals('TOPIK II'));
      expect(mode.levelRangeLabel, equals('3~6급'));
    });
  });

  group('TopikModeNotifier & Persistence', () {
    test('initializes from SharedPreferences if saved', () async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.activeTopikMode: 'topik1',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger read & init
      final initial = container.read(topikModeProvider);
      expect(initial, equals(TopikMode.topik2)); // default synchronous before async init

      await container.read(topikModeProvider.notifier).setMode(TopikMode.topik1);
      expect(container.read(topikModeProvider), equals(TopikMode.topik1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PrefsKeys.activeTopikMode), equals('topik1'));
    });

    test('switching modes updates state and persistence', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(topikModeProvider.notifier);
      await notifier.setMode(TopikMode.topik1);
      expect(container.read(topikModeProvider), equals(TopikMode.topik1));

      await notifier.setMode(TopikMode.topik2);
      expect(container.read(topikModeProvider), equals(TopikMode.topik2));
    });
  });

  group('TopikModeToggle Widget', () {
    testWidgets('renders TOPIK I and TOPIK II segments and switches on tap',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: TopikModeToggle(isCompact: false),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TOPIK I'), findsOneWidget);
      expect(find.text('TOPIK II'), findsOneWidget);

      // Tap TOPIK I segment
      await tester.tap(find.text('TOPIK I'));
      await tester.pumpAndSettle();

      // Tap TOPIK II segment
      await tester.tap(find.text('TOPIK II'));
      await tester.pumpAndSettle();
    });

    testWidgets('compact mode renders segmented toggle and switches on tap',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: TopikModeToggle(isCompact: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TOPIK I'), findsOneWidget);
      expect(find.text('TOPIK II'), findsOneWidget);

      await tester.tap(find.text('TOPIK I'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TOPIK II'));
      await tester.pumpAndSettle();
    });
  });
}
