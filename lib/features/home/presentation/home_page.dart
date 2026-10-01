import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/exam_schedule/data/exam_schedule_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_service.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_source_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final profile = ref.watch(userProfileProvider);
    final bookmarkSummary = ref.watch(bookmarkSummaryProvider);
    final examSchedules = ref.watch(examSchedulesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(strings.homeTitle),
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F8F6), Color(0xFFF8FBFF), Color(0xFFFFF8EA)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              // 1. Hero Header (User Profile & Streak)
              profile.when(
                data: (user) => _HomeHero(user: user, strings: strings),
                loading: () => _HomeHero(strings: strings),
                error: (_, _) => _HomeHero(strings: strings),
              ),
              const SizedBox(height: 20),

              // 2. Daily Word Challenge & OneVoca 4 Study Launchers Hub
              _DailyWordSection(strings: strings),
              const SizedBox(height: 22),

              // 3. Today's Grammar Focus
              _TodayGrammarSection(strings: strings),
              const SizedBox(height: 22),

              // 4. Quick Practice Shortcuts (Reading / Listening / Writing)
              _QuickPracticeSection(strings: strings),
              const SizedBox(height: 22),

              // 5. Exam Schedule & D-Day
              examSchedules.when(
                data: (schedules) {
                  final upcoming = schedules
                      .where(
                        (schedule) => schedule.examDate.isAfter(DateTime.now()),
                      )
                      .toList()
                    ..sort(
                      (left, right) =>
                          left.examDate.compareTo(right.examDate),
                    );
                  final schedule = upcoming.isNotEmpty ? upcoming.first : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.event_available_outlined,
                        title: strings.examSchedule,
                      ),
                      const SizedBox(height: 10),
                      if (schedule == null)
                        _EmptyExamScheduleCard(message: strings.noUpcomingExam)
                      else
                        _NextExamCard(schedule: schedule, strings: strings),
                      const SizedBox(height: 20),
                    ],
                  );
                },
                loading: () => _ExamScheduleLoadingCard(message: strings.loading),
                error: (error, _) => _ExamScheduleErrorCard(
                  message: strings.error,
                  retryTooltip: strings.retry,
                  onRetry: () => ref.invalidate(examSchedulesProvider),
                ),
              ),

              // 6. Bookmarks Summary Dashboard
              bookmarkSummary.when(
                data: (summary) => _StatusPanel(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: const Color(0xFFD07A21),
                  backgroundColor: const Color(0xFFFFF1DC),
                  title: strings.bookmarksSummary,
                  subtitle: strings.bookmarksSummaryDesc,
                  onTap: () => context.push('/bookmarks/questions'),
                  children: [
                    _MetricPill(
                      text: strings.questionsCount.replaceAll('{count}', '${summary.questions}'),
                      onTap: () => context.push('/bookmarks/questions'),
                    ),
                    _MetricPill(
                      text: strings.vocabCount.replaceAll('{count}', '${summary.vocabulary}'),
                      onTap: () => context.push('/bookmarks/vocabulary'),
                    ),
                    _MetricPill(
                      text: strings.grammarCount.replaceAll('{count}', '${summary.grammar}'),
                      onTap: () => context.push('/bookmarks/grammar'),
                    ),
                  ],
                ),
                loading: () => _StatusPanel(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: const Color(0xFFD07A21),
                  backgroundColor: const Color(0xFFFFF1DC),
                  title: strings.bookmarksSummary,
                  subtitle: strings.loading,
                ),
                error: (_, _) => _StatusPanel(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: const Color(0xFFD07A21),
                  backgroundColor: const Color(0xFFFFF1DC),
                  title: strings.bookmarksSummary,
                  subtitle: strings.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. Home Hero
// -------------------------------------------------------------
class _HomeHero extends StatelessWidget {
  const _HomeHero({this.user, required this.strings});

  final UserProfile? user;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final nickname = user?.nickname;
    final greeting = nickname == null
        ? strings.homeGreeting
            .replaceAll(', {name}님', '')
            .replaceAll('{name}님', '')
            .replaceAll(', {name}', '')
            .replaceAll('{name}', '')
            .replaceAll('!', '')
            .trim()
        : strings.homeGreeting.replaceAll('{name}', nickname);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDark.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.mintDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 3),
                    Text(
                      strings.homeSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Daily Streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      strings.streakDays.replaceAll('{days}', '7'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. Daily Word Section & OneVoca Hub
// -------------------------------------------------------------
class _DailyWordSection extends StatelessWidget {
  const _DailyWordSection({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.dailyWordChallenge,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.dailyWordChallengeDesc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/vocabulary'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      strings.all,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mintDark,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.mintDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // OneVoca 4 Study Launchers Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.85,
            children: [
              _OneVocaLauncherTile(
                icon: Icons.style_outlined,
                color: const Color(0xFF0F8C63),
                bgColor: const Color(0xFFE9F7EF),
                title: strings.flashcard,
                desc: strings.flashcardDesc,
                onTap: () => VocabularySourceSheet.show(context, VocabularyStudyMode.flashcard),
              ),
              _OneVocaLauncherTile(
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2E6BD9),
                bgColor: const Color(0xFFEAF1FF),
                title: strings.quiz,
                desc: strings.quizDesc,
                onTap: () => VocabularySourceSheet.show(context, VocabularyStudyMode.quiz),
              ),
              _OneVocaLauncherTile(
                icon: Icons.edit_note,
                color: const Color(0xFFD07A21),
                bgColor: const Color(0xFFFFF1DC),
                title: strings.dictation,
                desc: strings.dictationDesc,
                onTap: () => VocabularySourceSheet.show(context, VocabularyStudyMode.dictation),
              ),
              _OneVocaLauncherTile(
                icon: Icons.headphones_outlined,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF3E8FF),
                title: strings.autoplay,
                desc: strings.autoplayDesc,
                onTap: () => VocabularySourceSheet.show(context, VocabularyStudyMode.autoplay),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OneVocaLauncherTile extends StatelessWidget {
  const _OneVocaLauncherTile({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. Today's Grammar Section
// -------------------------------------------------------------
class _TodayGrammarSection extends ConsumerWidget {
  const _TodayGrammarSection({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grammarAsync = ref.watch(grammarProvider(const GrammarQuery(page: 1, limit: 1)));
    final targetLang = ref.watch(currentLanguageProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.todayGrammar,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.todayGrammarDesc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/grammar'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      strings.all,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF7C3AED)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grammar Body
          grammarAsync.when(
            data: (page) {
              final grammar = page.items.isNotEmpty ? page.items.first : null;
              if (grammar == null) return const SizedBox.shrink();

              final masterItem = ref.watch(masterGrammarDetailProvider(grammar.id)) ??
                  ref.watch(masterGrammarDetailProvider(grammar.pattern)) ??
                  grammar.toMasterGrammarItem();

              // Meaning translated to the configured language
              final meaningText = masterItem.getMeaning(targetLang);

              // Extract clean Korean example and single translation according to targetLang
              String koreanExample = '';
              String exampleTranslation = '';

              if (masterItem.examples.isNotEmpty) {
                final ex = masterItem.examples.first;
                koreanExample = ex.korean.trim();
                if (targetLang != 'ko') {
                  exampleTranslation = ex.getTranslation(targetLang).trim();
                }
              } else if (grammar.richExamples.isNotEmpty) {
                final ex = grammar.richExamples.first;
                koreanExample = ex.korean.trim();
                if (targetLang != 'ko') {
                  exampleTranslation = ex.getTranslation(targetLang).trim();
                }
              } else if (grammar.examples.isNotEmpty) {
                final raw = grammar.examples.first.trim();
                final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
                if (lines.isNotEmpty) {
                  koreanExample = lines.first;
                  if (targetLang != 'ko' && lines.length > 1) {
                    exampleTranslation = lines.sublist(1).join(' ');
                  }
                }
              }

              // In case koreanExample itself contained newlines (from legacy unparsed data)
              if (koreanExample.contains('\n')) {
                final lines = koreanExample.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
                if (lines.isNotEmpty) {
                  koreanExample = lines.first;
                  if (targetLang != 'ko' && exampleTranslation.isEmpty && lines.length > 1) {
                    exampleTranslation = lines.sublist(1).join(' ');
                  }
                }
              }

              final displayCategory = masterItem.category.isNotEmpty
                  ? masterItem.category
                  : (grammar.tags.isNotEmpty ? grammar.tags.first : '');

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            grammar.pattern,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (displayCategory.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              displayCategory,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF7C3AED)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => context.push('/grammar/${grammar.id}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      meaningText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                    if (koreanExample.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💬', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    koreanExample,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  if (exampleTranslation.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      exampleTranslation,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. Quick Practice Shortcuts
// -------------------------------------------------------------
class _QuickPracticeSection extends StatelessWidget {
  const _QuickPracticeSection({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.school_outlined,
          title: strings.quickPractice,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickPracticeButton(
                icon: Icons.menu_book_outlined,
                color: const Color(0xFF1D8F86),
                bgColor: const Color(0xFFE8F8F3),
                label: strings.readingShort,
                onTap: () => context.push('/reading-practice'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickPracticeButton(
                icon: Icons.headphones_outlined,
                color: const Color(0xFF2E6BD9),
                bgColor: const Color(0xFFEAF1FF),
                label: strings.listeningShort,
                onTap: () => context.push('/listening-practice'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickPracticeButton(
                icon: Icons.edit_note_outlined,
                color: const Color(0xFFD07A21),
                bgColor: const Color(0xFFFFF1DC),
                label: strings.writingShort,
                onTap: () => context.push('/writing-practice'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickPracticeButton extends StatelessWidget {
  const _QuickPracticeButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 5. Existing Shared Components (Exam & Bookmark)
// -------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mintDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _NextExamCard extends StatelessWidget {
  const _NextExamCard({required this.schedule, required this.strings});

  final TopikExamSchedule schedule;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd (E)');
    final diff = schedule.examDate.difference(DateTime.now()).inDays;
    final dDay = schedule.dDayLabel ??
        (diff == 0 ? 'D-Day' : (diff > 0 ? 'D-$diff' : 'D+${-diff}'));
    final examDate =
        schedule.examDateLabel ?? dateFormat.format(schedule.examDate);
    final registrationPeriod = schedule.registrationPeriodLabel;
    final resultDate = schedule.resultDateLabel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDark.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.examSchedule,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mintDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${strings.examDateLabel}: $examDate',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (registrationPeriod != null &&
                          registrationPeriod.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${strings.registrationPeriodLabel}: $registrationPeriod',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (resultDate != null && resultDate.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${strings.resultDateLabel}: $resultDate',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (schedule.feeLabel != null &&
                          schedule.feeLabel!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${strings.examFeeLabel}: ${schedule.feeLabel}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (schedule.location?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          schedule.location!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mintDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    dDay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final url = Uri.parse(
                  schedule.registrationUrl ?? 'https://www.topik.go.kr',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'topik.go.kr',
                      style: TextStyle(
                        color: AppColors.mintDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: AppColors.mintDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExamScheduleCard extends StatelessWidget {
  const _EmptyExamScheduleCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _ExamScheduleMessageCard(
      icon: Icons.event_busy_outlined,
      message: message,
    );
  }
}

class _ExamScheduleLoadingCard extends StatelessWidget {
  const _ExamScheduleLoadingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _ExamScheduleMessageCard(
      icon: Icons.hourglass_empty,
      message: message,
    );
  }
}

class _ExamScheduleErrorCard extends StatelessWidget {
  const _ExamScheduleErrorCard({
    required this.message,
    required this.retryTooltip,
    required this.onRetry,
  });

  final String message;
  final String retryTooltip;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ExamScheduleMessageCard(
      icon: Icons.error_outline,
      message: message,
      retryTooltip: retryTooltip,
      onRetry: onRetry,
    );
  }
}

class _ExamScheduleMessageCard extends StatelessWidget {
  const _ExamScheduleMessageCard({
    required this.icon,
    required this.message,
    this.retryTooltip,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final String? retryTooltip;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mintDark),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          if (onRetry != null)
            IconButton(
              tooltip: retryTooltip,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    this.children = const [],
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (children.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: children,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
