import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/features/admin/presentation/admin_question_sets_page.dart';
import 'package:topik_go/features/bookmarks/presentation/bookmarked_grammar_page.dart';
import 'package:topik_go/features/bookmarks/presentation/bookmarked_questions_page.dart';
import 'package:topik_go/features/bookmarks/presentation/bookmarked_vocabulary_page.dart';
import 'package:topik_go/features/auth/presentation/login_page.dart';
import 'package:topik_go/features/auth/presentation/register_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_detail_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_list_page.dart';
import 'package:topik_go/features/home/presentation/home_page.dart';
import 'package:topik_go/features/main_nav/presentation/main_shell_page.dart';
import 'package:topik_go/features/mock_exam/presentation/mock_exam_page.dart';
import 'package:topik_go/features/onboarding/presentation/ai_notice_page.dart';
import 'package:topik_go/features/onboarding/presentation/goal_level_page.dart';
import 'package:topik_go/features/onboarding/presentation/language_select_page.dart';
import 'package:topik_go/features/onboarding/presentation/splash_page.dart';
import 'package:topik_go/features/practice/presentation/practice_page.dart';
import 'package:topik_go/features/question_sets/presentation/question_set_detail_page.dart';
import 'package:topik_go/features/questions/presentation/question_detail_page.dart';
import 'package:topik_go/features/questions/presentation/question_list_page.dart';
import 'package:topik_go/features/questions/presentation/reading_practice_page.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_detail_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_list_page.dart';

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
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/question-sets/:id',
        builder: (context, state) {
          return QuestionSetDetailPage(id: state.pathParameters['id'] ?? '');
        },
      ),
      GoRoute(
        path: '/questions',
        builder: (context, state) {
          return QuestionListPage(
            initialSection: state.uri.queryParameters['section'],
            initialSetId: state.uri.queryParameters['set_id'],
          );
        },
      ),
      GoRoute(
        path: '/reading-practice',
        builder: (context, state) => const ReadingPracticePage(),
      ),
      GoRoute(
        path: '/questions/:id',
        builder: (context, state) {
          return QuestionDetailPage(id: state.pathParameters['id'] ?? '');
        },
      ),
      GoRoute(
        path: '/bookmarks/questions',
        builder: (context, state) => const BookmarkedQuestionsPage(),
      ),
      GoRoute(
        path: '/bookmarks/vocabulary',
        builder: (context, state) => const BookmarkedVocabularyPage(),
      ),
      GoRoute(
        path: '/bookmarks/grammar',
        builder: (context, state) => const BookmarkedGrammarPage(),
      ),
      GoRoute(
        path: '/grammar',
        builder: (context, state) => const GrammarListPage(),
      ),
      GoRoute(
        path: '/grammar/:id',
        builder: (context, state) {
          return GrammarDetailPage(id: state.pathParameters['id'] ?? '');
        },
      ),
      GoRoute(
        path: '/vocabulary',
        builder: (context, state) => const VocabularyListPage(),
      ),
      GoRoute(
        path: '/vocabulary/:id',
        builder: (context, state) {
          return VocabularyDetailPage(id: state.pathParameters['id'] ?? '');
        },
      ),
      GoRoute(
        path: '/admin/question-sets',
        builder: (context, state) => const AdminQuestionSetsPage(),
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
