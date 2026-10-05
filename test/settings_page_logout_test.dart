import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/auth/data/auth_repository.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

class _StaticLanguageNotifier extends LanguageNotifier {
  _StaticLanguageNotifier(this._initial);
  final String _initial;

  @override
  String build() => _initial;
}

class _FakeAuthRepository implements AuthRepository {
  bool logoutCalled = false;
  bool deleteAccountCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const Scaffold(body: Text('Login Screen')),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const Scaffold(body: Text('Language Screen')),
      ),
    ],
  );
}

void main() {
  const profile = UserProfile(
    id: 'u-logout',
    email: 'test@test.com',
    nickname: 'LogoutTester',
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

  testWidgets('Logout shows confirmation dialog in Korean; clicking 아니오 cancels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = _FakeAuthRepository();
    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap the logout button
    final logoutTile = find.text('로그아웃');
    expect(logoutTile, findsOneWidget);
    await tester.tap(logoutTile);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appeared with translated question
    expect(find.text('정말 로그아웃 하시겠습니까?'), findsOneWidget);
    expect(find.text('네'), findsOneWidget);
    expect(find.text('아니오'), findsOneWidget);

    // Tap "아니오"
    await tester.tap(find.text('아니오'));
    await tester.pumpAndSettle();

    // Verify dialog closed and logout was NOT called
    expect(find.text('정말 로그아웃 하시겠습니까?'), findsNothing);
    expect(fakeAuth.logoutCalled, isFalse);
  });

  testWidgets('Logout confirms and logs out when clicking 네 in Korean', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = _FakeAuthRepository();
    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap logout
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    // Tap "네"
    await tester.tap(find.text('네'));
    await tester.pumpAndSettle();

    // Verify logout was called and routed to login screen
    expect(fakeAuth.logoutCalled, isTrue);
    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('Logout confirmation is translated into Uzbek (uz)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = _FakeAuthRepository();
    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('uz')),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap logout (Chiqish)
    final logoutTile = find.text('Chiqish');
    expect(logoutTile, findsOneWidget);
    await tester.tap(logoutTile);
    await tester.pumpAndSettle();

    // Verify Uzbek confirmation message and buttons
    expect(find.text('Haqiqatan ham hisobdan chiqmoqchimisiz?'), findsOneWidget);
    expect(find.text('Ha'), findsOneWidget);
    expect(find.text("Yo'q"), findsOneWidget);

    // Tap "Ha" (Yes)
    await tester.tap(find.text('Ha'));
    await tester.pumpAndSettle();

    expect(fakeAuth.logoutCalled, isTrue);
    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('Delete account shows confirmation dialog and cancels when clicking 아니오', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = _FakeAuthRepository();
    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final deleteTile = find.text('회원 탈퇴');
    expect(deleteTile, findsOneWidget);
    await tester.tap(deleteTile);
    await tester.pumpAndSettle();

    expect(find.text('정말 탈퇴하시겠습니까? 계정을 삭제하면 학습 기록, 단어장, 오답노트 등 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
    expect(find.text('아니오'), findsOneWidget);

    await tester.tap(find.text('아니오'));
    await tester.pumpAndSettle();

    expect(find.text('정말 탈퇴하시겠습니까? 계정을 삭제하면 학습 기록, 단어장, 오답노트 등 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.'), findsNothing);
    expect(fakeAuth.deleteAccountCalled, isFalse);
  });

  testWidgets('Delete account confirms, clears preferences and navigates to /language in Korean', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'preferred_language_code': 'ko',
    });
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = _FakeAuthRepository();
    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(fakeAuth.deleteAccountCalled, isTrue);
    expect(find.text('Language Screen'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed'), isNull);
    expect(prefs.getString('preferred_language_code'), isNull);
  });

  testWidgets('Delete account confirmation is translated into Uzbek (uz)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = _FakeAuthRepository();
    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('uz')),
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final deleteTile = find.text('Hisobni o‘chirish');
    expect(deleteTile, findsOneWidget);
    await tester.tap(deleteTile);
    await tester.pumpAndSettle();

    expect(find.text('Haqiqatan ham hisobingizni o‘chirmoqchimisiz? Barcha o‘rganish tarixingiz, lug‘atlar va belgilar butunlay o‘chiriladi va ularni tiklab bo‘lmaydi.'), findsOneWidget);
    expect(find.text("O'chirish"), findsOneWidget);
    expect(find.text("Yo'q"), findsOneWidget);

    await tester.tap(find.text("O'chirish"));
    await tester.pumpAndSettle();

    expect(fakeAuth.deleteAccountCalled, isTrue);
    expect(find.text('Language Screen'), findsOneWidget);
  });
}
