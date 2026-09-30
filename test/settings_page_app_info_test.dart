import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

void main() {
  testWidgets('SettingsPage opens App Info modal sheet with project information when tapped', (
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

    // Verify project info modal elements are displayed
    expect(find.text('TOPIK GO'), findsWidgets);
    expect(find.text('v1.0.0 (Build 1)'), findsOneWidget);
    expect(find.text('주요 학습 기능 (Key Features)'), findsOneWidget);
    expect(find.text('기술 스택 (Tech Stack)'), findsOneWidget);
    expect(find.text('Framework'), findsOneWidget);
    expect(find.text('Flutter 3.41 / Dart 3.11'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);

    // Tap dismiss button
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    // Verify modal closed
    expect(find.text('v1.0.0 (Build 1)'), findsNothing);
  });
}
