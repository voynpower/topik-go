import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';

class AdminQuestionSetsPage extends ConsumerWidget {
  const AdminQuestionSetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionSets = ref.watch(questionSetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('문제 세트 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add),
      ),
      body: questionSets.when(
        data: (sets) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(questionSetsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sets.isEmpty ? 1 : sets.length,
            itemBuilder: (context, index) {
              if (sets.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('등록된 문제 세트가 없습니다.'),
                  ),
                );
              }
              return _AdminQuestionSetTile(set: sets[index]);
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    QuestionSet? set,
  }) async {
    final titleController = TextEditingController(text: set?.title);
    final sectionController = TextEditingController(text: set?.section);
    final levelController = TextEditingController(
      text: set == null ? '' : set.level.toString(),
    );

    final result =
        await showDialog<({String title, String section, int level})>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(set == null ? '문제 세트 추가' : '문제 세트 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '제목'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sectionController,
                    decoration: const InputDecoration(
                      labelText: '섹션',
                      hintText: 'reading / listening / writing / mock',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: levelController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '등급'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final section = sectionController.text.trim();
                    final level = int.tryParse(levelController.text.trim());
                    if (section.isEmpty || level == null) return;
                    Navigator.of(context).pop((
                      title: titleController.text.trim(),
                      section: section,
                      level: level,
                    ));
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );

    titleController.dispose();
    sectionController.dispose();
    levelController.dispose();
    if (result == null || !context.mounted) return;

    try {
      final repository = ref.read(questionSetRepositoryProvider);
      if (set == null) {
        await repository.createQuestionSet(
          title: result.title,
          section: result.section,
          level: result.level,
        );
      } else {
        await repository.updateQuestionSet(
          set.id,
          title: result.title,
          section: result.section,
          level: result.level,
        );
      }
      ref.invalidate(questionSetsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _AdminQuestionSetTile extends ConsumerWidget {
  const _AdminQuestionSetTile({required this.set});

  final QuestionSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(set.title),
        subtitle: Text('${set.sectionLabel} / ${set.level}급'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await AdminQuestionSetsPage()._openEditor(context, ref, set: set);
            }
            if (value == 'delete') {
              await ref
                  .read(questionSetRepositoryProvider)
                  .deleteQuestionSet(set.id);
              ref.invalidate(questionSetsProvider);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('수정')),
            PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
        ),
      ),
    );
  }
}
