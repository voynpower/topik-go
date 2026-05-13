import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';
import 'package:topik_go/features/questions/data/reading_practice_set.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionSets = ref.watch(questionSetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('학습')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('유형별 문제 풀기', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _MenuTile(
            title: '읽기 문제',
            subtitle:
                '${ReadingPracticeSet.level}급 / ${ReadingPracticeSet.total}문항',
            onTap: () => context.push('/reading-practice'),
          ),
          _MenuTile(
            title: '듣기 문제',
            subtitle: '듣기 문제 목록을 불러옵니다',
            onTap: () => context.push('/questions?section=listening'),
          ),
          _MenuTile(
            title: '쓰기 문제',
            subtitle: '쓰기 문제 목록을 불러옵니다',
            onTap: () => context.push('/questions?section=writing'),
          ),
          const SizedBox(height: 16),
          Text('문제 세트', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          questionSets.when(
            data: (sets) {
              if (sets.isEmpty) {
                return const _MenuTile(
                  title: '등록된 문제 세트가 없습니다',
                  subtitle: '백엔드에 question set 데이터를 추가하면 여기에 표시됩니다.',
                );
              }

              return Column(
                children: sets
                    .map((set) => _QuestionSetTile(set: set))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _MenuTile(
              title: '문제 세트를 불러오지 못했습니다',
              subtitle: error.toString(),
            ),
          ),
          const SizedBox(height: 16),
          Text('학습 도구', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _MenuTile(
            title: '북마크 문제',
            subtitle: '저장한 문제를 다시 풀어보세요',
            onTap: () => context.push('/bookmarks/questions'),
          ),
          const _MenuTile(title: '문제 해설 영상', subtitle: '문제 해설 영상을 열람해보세요'),
          _MenuTile(
            title: '단어장',
            subtitle: 'TOPIK 단어를 검색하고 저장하세요',
            onTap: () => context.push('/vocabulary'),
          ),
          _MenuTile(
            title: '북마크 단어',
            subtitle: '저장한 단어를 다시 확인하세요',
            onTap: () => context.push('/bookmarks/vocabulary'),
          ),
          _MenuTile(
            title: '문법 공부',
            subtitle: '문법 패턴을 검색하고 예문을 확인하세요',
            onTap: () => context.push('/grammar'),
          ),
          _MenuTile(
            title: '북마크 문법',
            subtitle: '저장한 문법을 다시 확인하세요',
            onTap: () => context.push('/bookmarks/grammar'),
          ),
          const _MenuTile(title: '오프라인 저장 데이터', subtitle: '오프라인 저장 데이터 열람'),
        ],
      ),
    );
  }
}

class _QuestionSetTile extends StatelessWidget {
  const _QuestionSetTile({required this.set});

  final QuestionSet set;

  @override
  Widget build(BuildContext context) {
    final countLabel = set.questionCount == null
        ? ''
        : ' / ${set.questionCount}문제';

    return _MenuTile(
      title: set.title,
      subtitle: '${set.sectionLabel} / ${set.level}급$countLabel',
      onTap: () => context.push('/question-sets/${set.id}'),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
