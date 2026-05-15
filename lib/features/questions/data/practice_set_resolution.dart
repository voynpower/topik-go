import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/question_sets/data/question_set_repository.dart';

/// Picks the best [QuestionSet.id] for practice after import, since DB UUIDs
/// differ from authoring fixtures. Falls back to [fallbackId] (dev default).
String? resolvedPracticeSetId({
  required List<QuestionSet> sets,
  required String section,
  required String? fallbackId,
  int? level,
}) {
  final target = section.toLowerCase();
  var candidates =
      sets.where((s) => s.section.toLowerCase() == target).toList();

  if (level != null) {
    final byLevel = candidates.where((s) => s.level == level).toList();
    // If we want a specific level, we MUST find a set for that level.
    // Otherwise, return null so we can fallback to querying by level only.
    if (byLevel.isEmpty) return null;
    candidates = byLevel;
  }

  if (candidates.isEmpty) return fallbackId;
  int score(QuestionSet s) {
    final n = s.questionCount ?? s.questions.length;
    return n;
  }

  candidates.sort((a, b) => score(b).compareTo(score(a)));
  final best = candidates.first;
  return best.id.isNotEmpty ? best.id : fallbackId;
}

String? readResolvedPracticeSetId(
  WidgetRef ref, {
  required String section,
  required String? fallbackId,
  int? level,
}) {
  return ref.read(questionSetsProvider).maybeWhen(
        data: (sets) => resolvedPracticeSetId(
          sets: sets,
          section: section,
          fallbackId: fallbackId,
          level: level,
        ),
        orElse: () => fallbackId,
      );
}
