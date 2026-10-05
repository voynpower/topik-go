import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/features/auth/presentation/login_page.dart';
import 'package:topik_go/features/auth/presentation/widgets/google_sign_in_button.dart';

void main() {
  group('GoogleSignInButton Widget Tests', () {
    testWidgets('renders GoogleLogo and text correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: () => tapped = true,
              text: 'Google 계정으로 계속하기',
            ),
          ),
        ),
      );

      expect(find.text('Google 계정으로 계속하기'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(GoogleSignInButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('displays CircularProgressIndicator when isLoading is true',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: () => tapped = true,
              isLoading: true,
              text: 'Google 계정으로 계속하기',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Google 계정으로 계속하기'), findsNothing);

      // Tap should be ignored while loading
      await tester.tap(find.byType(GoogleSignInButton));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });

  group('LoginPage UI Tests', () {
    testWidgets('shows Google login button and does NOT show Kakao login',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Verify GoogleSignInButton is present
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Google 계정으로 계속하기'), findsOneWidget);

      // Verify Kakao is completely removed
      expect(find.text('Login with Kakao'), findsNothing);
      expect(find.textContaining('Kakao'), findsNothing);
      expect(find.textContaining('카카오'), findsNothing);
    });
  });
}
