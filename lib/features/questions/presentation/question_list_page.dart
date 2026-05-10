import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';

class QuestionListPage extends ConsumerStatefulWidget {
  const QuestionListPage({super.key, this.initialSection, this.initialSetId});

  final String? initialSection;
  final String? initialSetId;

  @override
  ConsumerState<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends ConsumerState<QuestionListPage> {
  late String? _section = widget.initialSection;
  int? _level;
  int _page = 1;

  QuestionQuery get _query {
    return QuestionQuery(
      section: _section,
      level: _level,
      setId: widget.initialSetId,
      page: _page,
      limit: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('문제 목록')),
      body: Column(
        children: [
          _FilterBar(
            section: _section,
            level: _level,
            onSectionChanged: (section) {
              setState(() {
                _section = section;
                _page = 1;
              });
            },
            onLevelChanged: (level) {
              setState(() {
                _level = level;
                _page = 1;
              });
            },
          ),
          Expanded(
            child: questions.when(
              data: (page) => _QuestionList(
                page: page,
                onPrevious: page.page > 1
                    ? () => setState(() => _page = _page - 1)
                    : null,
                onNext: page.page * page.limit < page.total
                    ? () => setState(() => _page = _page + 1)
                    : null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(questionsProvider(_query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.section,
    required this.level,
    required this.onSectionChanged,
    required this.onLevelChanged,
  });

  final String? section;
  final int? level;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<int?> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: '전체',
                    selected: section == null,
                    onSelected: () => onSectionChanged(null),
                  ),
                  _FilterChip(
                    label: '읽기',
                    selected: section == 'reading',
                    onSelected: () => onSectionChanged('reading'),
                  ),
                  _FilterChip(
                    label: '듣기',
                    selected: section == 'listening',
                    onSelected: () => onSectionChanged('listening'),
                  ),
                  _FilterChip(
                    label: '쓰기',
                    selected: section == 'writing',
                    onSelected: () => onSectionChanged('writing'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: '전체 급수',
                    selected: level == null,
                    onSelected: () => onLevelChanged(null),
                  ),
                  for (final value in const [3, 4, 5, 6])
                    _FilterChip(
                      label: '$value급',
                      selected: level == value,
                      onSelected: () => onLevelChanged(value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final QuestionPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return const Center(child: Text('조건에 맞는 문제가 없습니다.'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('총 ${page.total}문항', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        ...page.items.map((question) => _QuestionTile(question: question)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                child: const Text('이전'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${page.page}'),
            ),
            Expanded(
              child: OutlinedButton(onPressed: onNext, child: const Text('다음')),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final titleNumber = question.questionNumber > 0
        ? '${question.questionNumber}번'
        : '문제';
    final levelLabel = question.level == null ? '' : ' / ${question.level}급';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          '$titleNumber ${question.prompt}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${_sectionLabel(question.section)}$levelLabel / ${question.questionType}',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/questions/${question.id}'),
      ),
    );
  }

  String _sectionLabel(String section) {
    switch (section.toLowerCase()) {
      case 'reading':
        return '읽기';
      case 'listening':
        return '듣기';
      case 'writing':
        return '쓰기';
      default:
        return section;
    }
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
