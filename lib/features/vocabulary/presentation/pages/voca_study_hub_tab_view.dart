import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_mastery_service.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';
import 'package:topik_go/features/vocabulary/presentation/vocabulary_source_sheet.dart';

class VocaStudyHubTabView extends ConsumerWidget {
  const VocaStudyHubTabView({super.key});

  void _openStudyMode(BuildContext context, VocabularyStudyMode mode) {
    VocabularySourceSheet.show(context, mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final masteryMap = ref.watch(wordMasteryProvider);
    final bookmarksAsync = ref.watch(bookmarkedVocabularyProvider);
    final savedCount = bookmarksAsync.asData?.value.length ?? 0;

    final masteredCount = masteryMap.values.where((s) => s == WordMasteryStatus.mastered).length;
    final unsureCount = masteryMap.values.where((s) => s == WordMasteryStatus.unsure).length;
    final hardCount = masteryMap.values.where((s) => s == WordMasteryStatus.hard).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
        children: [
          // 1. Header: Title + Streak Badges (OneVoca Benchmark voca_img6.jpeg)
          Row(
            children: [
              Text(
                strings.tabStudyHub,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              _StreakBadge(
                label: strings.streakConsecutive,
                count: 0,
                color: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFF7ED),
              ),
              const SizedBox(width: 8),
              _StreakBadge(
                label: strings.streakTotal,
                count: 14,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Daily Study Goal Card (OneVoca Benchmark)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.dailyStudyGoalTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: const [
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mintDark,
                          ),
                        ),
                        Text(
                          ' / 40',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 7,
                    backgroundColor: Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.dailyStudyGoalNotice,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. 2x2 Core Study Quadrant Card (OneVoca Style)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Row: Dictation (Left) | Quiz (Right)
                Row(
                  children: [
                    _StudyQuadrantTile(
                      icon: Icons.edit_note_rounded,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      title: strings.dictation,
                      desc: strings.dictationDesc,
                      onTap: () => _openStudyMode(context, VocabularyStudyMode.dictation),
                    ),
                    Container(width: 1, height: 96, color: const Color(0xFFF1F5F9)),
                    _StudyQuadrantTile(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFF5F3FF),
                      title: strings.quiz,
                      desc: strings.quizDesc,
                      onTap: () => _openStudyMode(context, VocabularyStudyMode.quiz),
                    ),
                  ],
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                // Bottom Row: Flashcards (Left) | Autoplay (Right)
                Row(
                  children: [
                    _StudyQuadrantTile(
                      icon: Icons.style_rounded,
                      iconColor: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFF0F9FF),
                      title: strings.flashcard,
                      desc: strings.flashcardDesc,
                      onTap: () => _openStudyMode(context, VocabularyStudyMode.flashcard),
                    ),
                    Container(width: 1, height: 96, color: const Color(0xFFF1F5F9)),
                    _StudyQuadrantTile(
                      icon: Icons.headphones_rounded,
                      iconColor: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                      title: strings.autoplay,
                      desc: strings.autoplayDesc,
                      onTap: () => _openStudyMode(context, VocabularyStudyMode.autoplay),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Review Hard Words Banner (if any)
          if (hardCount > 0) ...[
            Material(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => context.push('/vocabulary/flashcard?status=hard'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.reviewHardWords,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$hardCount${strings.wordsCount.replaceAll('{count}', '')}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 5. Review Saved Words Banner (if any)
          if (savedCount > 0) ...[
            Material(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => context.push('/vocabulary/flashcard?source=saved'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.reviewSavedWords,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.wordsSavedCount.replaceAll('{count}', '$savedCount'),
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 6. Study Record & Mastery Status Card
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => _showRecordsModal(context, strings, masteredCount, unsureCount, hardCount),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.insights_rounded, color: AppColors.mintDark, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              strings.studyRecord,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMasteryStatus(
                            label: strings.statusMastered,
                            count: masteredCount,
                            color: const Color(0xFF10B981),
                            bgColor: const Color(0xFFDCFCE7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniMasteryStatus(
                            label: strings.statusUnsure,
                            count: unsureCount,
                            color: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFEF3C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniMasteryStatus(
                            label: strings.statusHard,
                            count: hardCount,
                            color: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEE2E2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordsModal(
    BuildContext context,
    AppStrings strings,
    int mastered,
    int unsure,
    int hard,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              strings.studyRecord,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    title: strings.statusMastered,
                    value: '$mastered',
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatMiniCard(
                    title: strings.statusUnsure,
                    value: '$unsure',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatMiniCard(
                    title: strings.statusHard,
                    value: '$hard',
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyQuadrantTile extends StatelessWidget {
  const _StudyQuadrantTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMasteryStatus extends StatelessWidget {
  const _MiniMasteryStatus({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
