import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/exam_schedule/data/exam_schedule_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final questionSets = ref.watch(questionSetsProvider);
    final bookmarkSummary = ref.watch(bookmarkSummaryProvider);
    final nextExam = ref.watch(nextExamScheduleProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('홈'),
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              profile.when(
                data: (user) => _HomeHero(nickname: user.nickname),
                loading: () => const _HomeHero(),
                error: (_, _) => const _HomeHero(),
              ),
              const SizedBox(height: 22),
              nextExam.when(
                data: (schedule) {
                  debugPrint('HomePage nextExam data: $schedule');
                  if (schedule == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(
                        icon: Icons.event_available_outlined,
                        title: '시험 일정',
                      ),
                      const SizedBox(height: 10),
                      _NextExamCard(schedule: schedule),
                      const SizedBox(height: 20),
                    ],
                  );
                },
                loading: () {
                  debugPrint('HomePage nextExam: loading');
                  return const SizedBox.shrink();
                },
                error: (err, stack) {
                  debugPrint('HomePage nextExam: error $err');
                  return const SizedBox.shrink();
                },
              ),
              const _SectionTitle(
                icon: Icons.insights_outlined,
                title: '오늘의 학습',
              ),
              const SizedBox(height: 10),
              questionSets.when(
                data: (sets) {
                  final reading = sets
                      .where((set) => set.section.toLowerCase() == 'reading')
                      .length;
                  final listening = sets
                      .where((set) => set.section.toLowerCase() == 'listening')
                      .length;
                  final writing = sets
                      .where((set) => set.section.toLowerCase() == 'writing')
                      .length;

                  return _StatusPanel(
                    icon: Icons.school_outlined,
                    iconColor: AppColors.mintDark,
                    backgroundColor: const Color(0xFFE8F8F3),
                    title: '학습 콘텐츠',
                    subtitle: '사용 가능한 문제 세트 ${sets.length}개',
                    children: [
                      _MetricPill(label: '읽기', count: reading),
                      _MetricPill(label: '듣기', count: listening),
                      _MetricPill(label: '쓰기', count: writing),
                    ],
                  );
                },
                loading: () => const _StatusPanel(
                  icon: Icons.school_outlined,
                  iconColor: AppColors.mintDark,
                  backgroundColor: Color(0xFFE8F8F3),
                  title: '학습 콘텐츠',
                  subtitle: '문제 세트를 불러오는 중...',
                ),
                error: (_, _) => const _StatusPanel(
                  icon: Icons.school_outlined,
                  iconColor: AppColors.mintDark,
                  backgroundColor: Color(0xFFE8F8F3),
                  title: '학습 콘텐츠',
                  subtitle: '문제 세트를 불러오지 못했습니다.',
                ),
              ),
              const SizedBox(height: 12),
              bookmarkSummary.when(
                data: (summary) => _StatusPanel(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: const Color(0xFFD07A21),
                  backgroundColor: const Color(0xFFFFF1DC),
                  title: '북마크',
                  subtitle: '다시 보고 싶은 자료를 모아두는 공간입니다.',
                  children: [
                    _MetricPill(label: '문제', count: summary.questions),
                    _MetricPill(label: '단어', count: summary.vocabulary),
                    _MetricPill(label: '문법', count: summary.grammar),
                  ],
                ),
                loading: () => const _StatusPanel(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: Color(0xFFD07A21),
                  backgroundColor: Color(0xFFFFF1DC),
                  title: '북마크',
                  subtitle: '북마크 정보를 불러오는 중...',
                ),
                error: (_, _) => const _StatusPanel(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: Color(0xFFD07A21),
                  backgroundColor: Color(0xFFFFF1DC),
                  title: '북마크',
                  subtitle: '북마크 정보를 불러오지 못했습니다.',
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                icon: Icons.flash_on_outlined,
                title: '바로 시작',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.menu_book_outlined,
                      iconColor: const Color(0xFF1D8F86),
                      backgroundColor: const Color(0xFFE8F8F3),
                      title: '학습',
                      subtitle: '유형별 연습',
                      onTap: () => context.go('/main/practice'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.edit_note_outlined,
                      iconColor: const Color(0xFF2E6BD9),
                      backgroundColor: const Color(0xFFEAF1FF),
                      title: '모의고사',
                      subtitle: '실전 풀이',
                      onTap: () => context.go('/main/mock'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({this.nickname});

  final String? nickname;

  @override
  Widget build(BuildContext context) {
    final greeting = nickname == null ? '안녕하세요!' : '안녕하세요, $nickname님!';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDark.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: AppColors.mintDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '오늘도 TOPIK 목표에 맞춰 차근차근 학습해보세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _NextExamCard extends StatelessWidget {
  const _NextExamCard({required this.schedule});

  final TopikExamSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd (E)', 'ko_KR');
    final diff = schedule.examDate.difference(DateTime.now()).inDays;
    final dDay = schedule.dDayLabel ?? 'D-$diff';
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '다음 시험 일정',
                    style: TextStyle(
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
                    '시험일: $examDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (registrationPeriod != null &&
                      registrationPeriod.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '접수기간: $registrationPeriod',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (resultDate != null && resultDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '결과발표: $resultDate',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (schedule.location?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      schedule.location!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 74,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  Row(children: children),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Text(
          '$label $count',
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
