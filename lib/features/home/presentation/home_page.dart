import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(title: const Text('홈')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          profile.when(
            data: (user) => Text(
              '안녕하세요, ${user.nickname}님!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            loading: () =>
                Text('안녕하세요!', style: Theme.of(context).textTheme.titleLarge),
            error: (_, _) =>
                Text('안녕하세요!', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 6),
          Text(
            '당신의 학습을 응원합니다!',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mintDark),
          ),
          const SizedBox(height: 16),
          nextExam.when(
            data: (schedule) {
              debugPrint('HomePage nextExam data: $schedule');
              if (schedule == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NextExamCard(schedule: schedule),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 학습',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  questionSets.when(
                    data: (sets) => Text('사용 가능한 문제 세트 ${sets.length}개'),
                    loading: () => const Text('문제 세트를 불러오는 중...'),
                    error: (_, _) => const Text('문제 세트를 불러오지 못했습니다.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '북마크',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  bookmarkSummary.when(
                    data: (summary) => Row(
                      children: [
                        _BookmarkCount(label: '문제', count: summary.questions),
                        _BookmarkCount(label: '단어', count: summary.vocabulary),
                        _BookmarkCount(label: '문법', count: summary.grammar),
                      ],
                    ),
                    loading: () => const Text('북마크 정보를 불러오는 중...'),
                    error: (_, _) => const Text('북마크 정보를 불러오지 못했습니다.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '모의고사 풀기',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  questionSets.when(
                    data: (sets) {
                      final mockSets = sets
                          .where((set) => set.section.toLowerCase() == 'mock')
                          .length;
                      return Text(
                        mockSets > 0
                            ? '모의고사 세트 $mockSets개'
                            : '등록된 모의고사 세트가 없습니다.',
                      );
                    },
                    loading: () => const Text('모의고사 정보를 불러오는 중...'),
                    error: (_, _) => const Text('모의고사 정보를 불러오지 못했습니다.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

    return Card(
      color: AppColors.mint.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.mint.withValues(alpha: 0.3)),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mintDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dDay,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkCount extends StatelessWidget {
  const _BookmarkCount({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$count', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
