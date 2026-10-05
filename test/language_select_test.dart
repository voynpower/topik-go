import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/onboarding/presentation/language_select_page.dart';
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

  testWidgets('LanguageSelectPage updates currentLanguageProvider when language is selected', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(_MockUserRepo()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LanguageSelectPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default is Korean ('ko')
    expect(container.read(currentLanguageProvider), 'ko');

    // Tap on Uzbek ('O\'zbekcha')
    final uzbekTile = find.text("O'zbekcha");
    expect(uzbekTile, findsOneWidget);
    await tester.tap(uzbekTile);
    await tester.pumpAndSettle();

    // currentLanguageProvider and appStringsProvider should now be 'uz'
    expect(container.read(currentLanguageProvider), 'uz');
    expect(container.read(appStringsProvider).locale, 'uz');
    expect(find.text('Keyingi qadam'), findsOneWidget);

    // Tap on English
    final englishTile = find.text('English');
    expect(englishTile, findsWidgets);
    await tester.tap(englishTile.first);
    await tester.pumpAndSettle();

    expect(container.read(currentLanguageProvider), 'en');
    expect(container.read(appStringsProvider).locale, 'en');
    expect(find.text('Next Step'), findsOneWidget);
  });
}
