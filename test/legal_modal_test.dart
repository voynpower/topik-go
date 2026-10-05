import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/legal/legal_documents.dart';
import 'package:topik_go/core/legal/legal_modal.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/auth/presentation/register_page.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class _StaticLanguageNotifier extends LanguageNotifier {
  _StaticLanguageNotifier(this._initial);
  final String _initial;

  @override
  String build() => _initial;
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
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );
}

void main() {
  const profile = UserProfile(
    id: 'u-legal',
    email: 'legal@test.com',
    nickname: 'LegalTester',
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

  testWidgets('SettingsPage shows Terms of Service and Privacy Policy and opens modal in Korean', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('ko')),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Terms and Policies section
    expect(find.text('약관 및 정책'), findsOneWidget);
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);

    // Tap Terms of Service
    await tester.tap(find.text('서비스 이용약관'));
    await tester.pumpAndSettle();

    // Modal should be visible
    expect(find.text('TOPIK GO 서비스 이용약관'), findsOneWidget);
    expect(find.text('제1조 (목적)'), findsOneWidget);
    expect(find.text('브라우저에서 열기'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('제1조 (목적)'), findsNothing);

    // Tap Privacy Policy
    await tester.tap(find.text('개인정보처리방침'));
    await tester.pumpAndSettle();

    expect(find.text('TOPIK GO 개인정보처리방침'), findsOneWidget);
    expect(find.text('1. 수집하는 개인정보 항목'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('1. 수집하는 개인정보 항목'), findsNothing);
  });

  testWidgets('SettingsPage displays Terms and Privacy in Uzbek (uz)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = _buildTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('uz')),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shartlar va qoidalar'), findsOneWidget);
    expect(find.text('Foydalanish shartlari'), findsOneWidget);
    expect(find.text('Maxfiylik siyosati'), findsOneWidget);
  });

  testWidgets('Direct showLegalModal invocation renders terms and privacy properly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentLanguageProvider.overrideWith(() => _StaticLanguageNotifier('en')),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showLegalModal(context, type: LegalDocumentType.termsOfService),
                child: const Text('Open Legal'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Legal'));
    await tester.pumpAndSettle();

    expect(find.text('TOPIK GO Terms of Service'), findsOneWidget);
    expect(find.text('Article 1 (Purpose)'), findsOneWidget);
    expect(find.text('Open in Browser'), findsOneWidget);
  });
}
