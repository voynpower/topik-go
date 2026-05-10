import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';

class MockExamPage extends ConsumerWidget {
  const MockExamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionSets = ref.watch(questionSetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('모의고사')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('모의고사 풀기', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '실제 시험과 같은 환경에서 모의고사 풀기!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.mintDark),
            ),
            const SizedBox(height: 16),
            questionSets.when(
              data: (sets) {
                final mockSets = sets.where(_isMockLike).toList();
                if (mockSets.isEmpty) {
                  return const _MockExamCard(
                    title: '등록된 모의고사가 없습니다',
                    subtitle: '백엔드에 모의고사 question set을 추가하면 여기에 표시됩니다.',
                  );
                }

                final first = mockSets.first;
                return _MockExamCard(
                  title: first.title,
                  subtitle: '${first.sectionLabel} / ${first.level}급',
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _MockExamCard(
                title: '모의고사를 불러오지 못했습니다',
                subtitle: error.toString(),
              ),
            ),
            const Spacer(),
            FilledButton(onPressed: () {}, child: const Text('시작하기')),
          ],
        ),
      ),
    );
  }

  bool _isMockLike(QuestionSet set) {
    final section = set.section.toLowerCase();
    return section == 'mock' || section == 'exam';
  }
}

class _MockExamCard extends StatelessWidget {
  const _MockExamCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 6),
            Text('Ready', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}
