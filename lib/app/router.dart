import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/features/admin/presentation/admin_question_sets_page.dart';
import 'package:topik_go/features/bookmarks/presentation/bookmarked_questions_page.dart';
import 'package:topik_go/features/auth/presentation/login_page.dart';
import 'package:topik_go/features/auth/presentation/register_page.dart';
import 'package:topik_go/features/explanation_video/presentation/explanation_video_list_page.dart';
import 'package:topik_go/features/explanation_video/presentation/video_player_page.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';
import 'package:topik_go/features/grammar/presentation/grammar_detail_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_flashcard_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_list_page.dart';
import 'package:topik_go/features/grammar/presentation/grammar_quiz_page.dart';
import 'package:topik_go/features/home/presentation/home_page.dart';
import 'package:topik_go/features/main_nav/presentation/main_shell_page.dart';
import 'package:topik_go/features/mock_exam/presentation/mock_exam_page.dart';
import 'package:topik_go/features/onboarding/presentation/ai_notice_page.dart';
import 'package:topik_go/features/onboarding/presentation/goal_level_page.dart';
import 'package:topik_go/features/onboarding/presentation/language_select_page.dart';
import 'package:topik_go/features/onboarding/presentation/splash_page.dart';
import 'package:topik_go/features/practice/presentation/practice_page.dart';
import 'package:topik_go/features/question_sets/presentation/question_set_detail_page.dart';
import 'package:topik_go/features/questions/presentation/listening_practice_page.dart';
import 'package:topik_go/features/questions/presentation/question_detail_page.dart';
import 'package:topik_go/features/questions/presentation/question_list_page.dart';
import 'package:topik_go/features/questions/presentation/reading_practice_page.dart';
import 'package:topik_go/features/questions/presentation/writing_practice_page.dart';
import 'package:topik_go/features/settings/presentation/settings_page.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_autoplay_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_detail_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_dictation_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_flashcard_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_page.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_quiz_page.dart';

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
        path: '/reading-practice/:level',
        builder: (context, state) {
          final parsed = int.tryParse(state.pathParameters['level'] ?? '');
          return ReadingPracticePage(level: parsed);
        },
      ),
      GoRoute(
        path: '/listening-practice',
        builder: (context, state) => const ListeningPracticePage(),
      ),
      GoRoute(
        path: '/listening-practice/:level',
        builder: (context, state) {
          final parsed = int.tryParse(state.pathParameters['level'] ?? '');
          return ListeningPracticePage(level: parsed);
        },
      ),
      GoRoute(
        path: '/writing-practice',
        builder: (context, state) => const WritingPracticePage(),
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
        builder: (context, state) => const VocabularyPage(initialTabIndex: 0, initialOnlySaved: true),
      ),
      GoRoute(
        path: '/bookmarks/grammar',
        builder: (context, state) => const GrammarListPage(initialLevelGroup: GrammarLevelGroup.saved),
      ),
      GoRoute(
        path: '/grammar',
        builder: (context, state) {
          final levelParam = state.uri.queryParameters['level'];
          final initialLevel = levelParam == 'saved'
              ? GrammarLevelGroup.saved
              : GrammarLevelGroup.all;
          return GrammarListPage(initialLevelGroup: initialLevel);
        },
      ),
      GoRoute(
        path: '/grammar/flashcard',
        builder: (context, state) {
          final sourceParam = state.uri.queryParameters['source'];
          final source = sourceParam == 'saved'
              ? const GrammarStudySource.saved()
              : const GrammarStudySource.all();
          return GrammarFlashcardPage(source: source);
        },
      ),
      GoRoute(
        path: '/grammar/quiz',
        builder: (context, state) {
          final sourceParam = state.uri.queryParameters['source'];
          final source = sourceParam == 'saved'
              ? const GrammarStudySource.saved()
              : const GrammarStudySource.all();
          return GrammarQuizPage(source: source);
        },
      ),
      GoRoute(
        path: '/grammar/:id',
        builder: (context, state) {
          return GrammarDetailPage(id: state.pathParameters['id'] ?? '');
        },
      ),
      GoRoute(
        path: '/vocabulary',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = tabParam == 'study' ? 1 : 0;
          final sourceParam = state.uri.queryParameters['source'];
          final initialOnlySaved = sourceParam == 'all'
              ? false
              : (sourceParam == 'saved' ? true : null);
          return VocabularyPage(
            initialTabIndex: initialTab,
            initialOnlySaved: initialOnlySaved,
          );
        },
      ),
      GoRoute(
        path: '/vocabulary/flashcard',
        builder: (context, state) {
          final sourceParam = state.uri.queryParameters['source'];
          final source = sourceParam == 'all'
              ? const StudyWordSource.all()
              : const StudyWordSource.saved();
          return VocabularyFlashcardPage(source: source);
        },
      ),
      GoRoute(
        path: '/vocabulary/quiz',
        builder: (context, state) {
          final sourceParam = state.uri.queryParameters['source'];
          final source = sourceParam == 'all'
              ? const StudyWordSource.all()
              : const StudyWordSource.saved();
          return VocabularyQuizPage(source: source);
        },
      ),
      GoRoute(
        path: '/vocabulary/dictation',
        builder: (context, state) {
          final sourceParam = state.uri.queryParameters['source'];
          final source = sourceParam == 'all'
              ? const StudyWordSource.all()
              : const StudyWordSource.saved();
          return VocabularyDictationPage(source: source);
        },
      ),
      GoRoute(
        path: '/vocabulary/autoplay',
        builder: (context, state) {
          final sourceParam = state.uri.queryParameters['source'];
          final source = sourceParam == 'all'
              ? const StudyWordSource.all()
              : const StudyWordSource.saved();
          return VocabularyAutoplayPage(source: source);
        },
      ),
      GoRoute(
        path: '/vocabulary/:id',
        builder: (context, state) {
          return VocabularyDetailPage(id: state.pathParameters['id'] ?? '');
        },
      ),
      GoRoute(
        path: '/explanation-videos',
        builder: (context, state) => const ExplanationVideoListPage(),
      ),
      GoRoute(
        path: '/video-player',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'] ?? '영상 재생';
          return VideoPlayerPage(url: url, title: title);
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
