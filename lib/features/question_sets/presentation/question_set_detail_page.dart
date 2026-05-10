import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';

final questionSetDetailProvider = FutureProvider.family<QuestionSet, String>((
  ref,
  id,
) {
  return ref.watch(questionSetRepositoryProvider).getQuestionSet(id);
});

class QuestionSetDetailPage extends ConsumerWidget {
  const QuestionSetDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionSet = ref.watch(questionSetDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('문제 세트')),
      body: questionSet.when(
        data: (set) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(set.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${set.sectionLabel} / ${set.level}급 / ${set.questionCount ?? set.questions.length}문항',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.mintDark),
            ),
            const SizedBox(height: 16),
            if (set.questions.isEmpty)
              const _EmptyDetail()
            else
              ...set.questions.map((question) => _QuestionCard(question)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.push('/questions?set_id=${set.id}'),
              child: const Text('전체 문제 목록 보기'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(questionSetDetailProvider(id)),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard(this.question);

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${question.questionNumber}번',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(question.questionType),
              ],
            ),
            if (question.passageText?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(question.passageText!),
              ),
            ],
            const SizedBox(height: 12),
            Text(question.prompt),
            if (question.options.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...question.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${option.label}. ${option.text}'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/questions/${question.id}'),
                child: const Text('풀기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('이 문제 세트에는 아직 문제가 없습니다.'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
