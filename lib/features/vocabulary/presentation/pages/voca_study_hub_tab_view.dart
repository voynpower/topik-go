import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_mastery_service.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';
import 'package:topik_go/features/vocabulary/presentation/sheets/voca_study_setup_sheet.dart';

class VocaStudyHubTabView extends ConsumerWidget {
  const VocaStudyHubTabView({super.key});

  void _openSetup(BuildContext context, VocabularyStudyMode mode) {
    VocaStudySetupSheet.show(context, mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final masteryMap = ref.watch(wordMasteryProvider);

    final masteredCount = masteryMap.values.where((s) => s == WordMasteryStatus.mastered).length;
    final hardCount = masteryMap.values.where((s) => s == WordMasteryStatus.hard).length;
    const dailyGoal = 40;
    final progress = (masteredCount / dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF13161F), // OneVoca 딥 다크 배경
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          // 1. Streak Header (voca_img6.jpeg)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.tabStudyHub,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  _StreakBadge(
                    label: '연속',
                    count: 7,
                    flameColor: const Color(0xFFF97316),
                  ),
                  const SizedBox(width: 8),
                  _StreakBadge(
                    label: '누적',
                    count: 42,
                    flameColor: const Color(0xFFF97316),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Daily Goal Progress Card (voca_img6.jpeg)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2D3342)),
            ),
            child: Row(
              children: [
                // Flame Icon Circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: progress >= 1.0
                        ? const Color(0xFFF97316).withValues(alpha: 0.2)
                        : const Color(0xFF272C3E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    progress >= 1.0 ? '🔥' : '🕯️',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$masteredCount / $dailyGoal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.dailyStudyGoalNotice,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFF272C3E),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. OneVoca 4 Study Modes Grid (2x2) - voca_img6.jpeg
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2D3342)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StudyModeGridCard(
                        icon: Icons.edit,
                        iconColor: const Color(0xFF818CF8),
                        title: strings.dictation,
                        onTap: () => _openSetup(context, VocabularyStudyMode.dictation),
                      ),
                    ),
                    Container(width: 1, height: 90, color: const Color(0xFF2D3342)),
                    Expanded(
                      child: _StudyModeGridCard(
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF818CF8),
                        title: strings.quiz,
                        onTap: () => _openSetup(context, VocabularyStudyMode.quiz),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFF2D3342)),
                Row(
                  children: [
                    Expanded(
                      child: _StudyModeGridCard(
                        icon: Icons.style,
                        iconColor: const Color(0xFF818CF8),
                        title: strings.flashcard,
                        onTap: () => _openSetup(context, VocabularyStudyMode.flashcard),
                      ),
                    ),
                    Container(width: 1, height: 90, color: const Color(0xFF2D3342)),
                    Expanded(
                      child: _StudyModeGridCard(
                        icon: Icons.fast_forward_rounded,
                        iconColor: const Color(0xFF818CF8),
                        title: strings.autoplay,
                        onTap: () => _openSetup(context, VocabularyStudyMode.autoplay),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Study Records & Calendar (voca_img6.jpeg)
          Material(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () {
                _showRecordsModal(context, strings, masteredCount, hardCount);
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF2D3342)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF818CF8), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      strings.studyRecord,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 5. Hard Word Special Focus (취약 단어 집중 공략 카드)
          if (hardCount > 0)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1A24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4C1D2F)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B1F37),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🔴', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '어려운 단어 $hardCount개 복습하기',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '아직 헷갈리는 단어만 모아서 플래시카드로 마스터하세요.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFFDA4AF)),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      context.push('/vocabulary/flashcard?source=all&status=hard');
                    },
                    child: const Text('복습', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showRecordsModal(BuildContext context, AppStrings strings, int mastered, int hard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E222D),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              strings.studyRecord,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    title: '완전 정복',
                    value: '$mastered개',
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatMiniCard(
                    title: '집중 복습 필요',
                    value: '$hard개',
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '🔥 매일 꾸준한 단어 학습이 TOPIK 고득점의 열쇠입니다.',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
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
    required this.flameColor,
  });

  final String label;
  final int count;
  final Color flameColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D3342)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Text('🔥', style: TextStyle(fontSize: 13, color: flameColor)),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StudyModeGridCard extends StatelessWidget {
  const _StudyModeGridCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272C3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333B4F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
