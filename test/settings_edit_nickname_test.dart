import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
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

class _MockUserRepo implements UserRepository {
  _MockUserRepo(this.currentProfile);

  UserProfile currentProfile;
  Map<String, dynamic>? lastUpdatedData;

  @override
  Future<UserProfile> getProfile() async => currentProfile;

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    lastUpdatedData = data;
    currentProfile = UserProfile(
      id: currentProfile.id,
      email: currentProfile.email,
      nickname: data['nickname'] as String? ?? currentProfile.nickname,
      role: currentProfile.role,
      languageCode: currentProfile.languageCode,
      targetLevel: currentProfile.targetLevel,
      timezone: currentProfile.timezone,
      fontScale: currentProfile.fontScale,
      timerMode: currentProfile.timerMode,
      themeColor: currentProfile.themeColor,
      homeLayout: currentProfile.homeLayout,
      practiceLayout: currentProfile.practiceLayout,
    );
    return currentProfile;
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
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const initialProfile = UserProfile(
    id: 'u-123',
    email: 'user@example.com',
    nickname: 'OriginalName',
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

  testWidgets('Nickname tile opens edit dialog and validates 2-20 characters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = _MockUserRepo(initialProfile);
    final strings = AppStrings.of('ko');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockRepo),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
          appStringsProvider.overrideWithValue(strings),
        ],
        child: MaterialApp.router(
          routerConfig: _buildTestRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial nickname is visible
    expect(find.text('OriginalName'), findsOneWidget);

    // 2. Tap on the username tile
    await tester.tap(find.text('OriginalName'));
    await tester.pumpAndSettle();

    // 3. Verify dialog is open with pre-filled text
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    expect(find.widgetWithText(TextField, 'OriginalName'), findsOneWidget);

    // 4. Test validation: Too short (1 char)
    await tester.enterText(textFieldFinder, 'A');
    await tester.tap(find.text(strings.save));
    await tester.pumpAndSettle();

    expect(find.text('닉네임은 2자 이상 20자 이하로 입력해 주세요.'), findsOneWidget);
    expect(mockRepo.lastUpdatedData, isNull);

    // 5. Test validation: Too long (> 20 chars)
    await tester.enterText(textFieldFinder, '123456789012345678901');
    await tester.tap(find.text(strings.save));
    await tester.pumpAndSettle();

    expect(find.text('닉네임은 2자 이상 20자 이하로 입력해 주세요.'), findsOneWidget);
    expect(mockRepo.lastUpdatedData, isNull);

    // 6. Valid update
    await tester.enterText(textFieldFinder, 'NewAwesomeName');
    await tester.tap(find.text(strings.save));
    await tester.pumpAndSettle();

    // Dialog closed
    expect(find.byType(AlertDialog), findsNothing);
    expect(mockRepo.lastUpdatedData, {'nickname': 'NewAwesomeName'});

    // Screen automatically displays updated nickname
    expect(find.text('NewAwesomeName'), findsOneWidget);
  });
}
