import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/features/auth/presentation/login_page.dart';
import 'package:topik_go/features/home/presentation/home_page.dart';
import 'package:topik_go/features/main_nav/presentation/main_shell_page.dart';
import 'package:topik_go/features/mock_exam/presentation/mock_exam_page.dart';
import 'package:topik_go/features/onboarding/presentation/ai_notice_page.dart';
import 'package:topik_go/features/onboarding/presentation/goal_level_page.dart';
import 'package:topik_go/features/onboarding/presentation/language_select_page.dart';
import 'package:topik_go/features/onboarding/presentation/splash_page.dart';
import 'package:topik_go/features/practice/presentation/practice_page.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/ai-notice',
        builder: (context, state) => const AiNoticePage(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectPage(),
      ),
      GoRoute(
        path: '/goal-level',
        builder: (context, state) => const GoalLevelPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/main/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/main/practice',
                builder: (context, state) => const PracticePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/main/mock',
                builder: (context, state) => const MockExamPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/main/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
