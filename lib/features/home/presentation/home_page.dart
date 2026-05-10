import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final questionSets = ref.watch(questionSetsProvider);
    final bookmarkSummary = ref.watch(bookmarkSummaryProvider);

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
