import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class _StaticLanguageNotifier extends LanguageNotifier {
  _StaticLanguageNotifier(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}

void main() {
  testWidgets('SettingsPage opens App Info modal in Korean with concise vision and simple tech stack', (
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
      languageCode: 'ko',
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
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
        ],
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify App Info tile is present
    final appInfoFinder = find.text('앱 정보');
    expect(appInfoFinder, findsOneWidget);

    // Tap on the App Info tile
    await tester.tap(appInfoFinder);
    await tester.pumpAndSettle();

    // Verify project info modal elements are displayed in Korean
    expect(find.text('TOPIK GO'), findsWidgets);
    expect(find.text('v1.0.0 (최신 버전)'), findsOneWidget);
    expect(find.text('주요 기능'), findsOneWidget);
    expect(find.text('영역별 기출 풀이'), findsOneWidget);
    expect(find.text('실전 모의고사'), findsOneWidget);
    expect(find.text('기술 스택'), findsOneWidget);
    expect(find.text('Flutter 3.41 / Dart 3.11'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);

    // Verify no redundant complex architecture table
    expect(find.text('Feature-First Clean Architecture'), findsNothing);
    expect(find.text('NestJS Backend / AWS CloudFront'), findsNothing);

    // Tap dismiss button
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    // Verify modal closed
    expect(find.text('v1.0.0 (최신 버전)'), findsNothing);
  });

  testWidgets('SettingsPage translates App Info modal into Uzbek (uz) with simple tech stack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const profile = UserProfile(
      id: 'u-2',
      email: 'uzbek_user@test.com',
      nickname: 'Otabek',
      role: 'user',
      languageCode: 'uz',
      targetLevel: 4,
      timezone: '+05:00',
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
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('uz')),
        ],
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap the App Info tile
    final appInfoFinder = find.byIcon(Icons.info_outline);
    expect(appInfoFinder, findsOneWidget);
    await tester.tap(appInfoFinder);
    await tester.pumpAndSettle();

    // Verify modal elements are displayed in Uzbek
    expect(find.text('TOPIK GO'), findsWidgets);
    expect(find.text('v1.0.0 (So‘nggi versiya)'), findsOneWidget);
    expect(find.text('Asosiy imkoniyatlar'), findsOneWidget);
    expect(find.text('Bo‘limlar bo‘yicha mashq'), findsOneWidget);
    expect(find.text('Texnologiyalar'), findsOneWidget);
    expect(find.text('Flutter 3.41 / Dart 3.11'), findsOneWidget);
    expect(find.text('Tushundim'), findsOneWidget);

    // Tap dismiss button in Uzbek
    await tester.tap(find.text('Tushundim'));
    await tester.pumpAndSettle();

    // Verify modal closed
    expect(find.text('v1.0.0 (So‘nggi versiya)'), findsNothing);
  });
}
