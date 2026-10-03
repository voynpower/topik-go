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
  var candidates = sets
      .where((s) => s.section.toLowerCase() == target)
      .toList();

  if (level != null) {
    final byLevel = candidates.where((s) => s.level == level).toList();
    final actualTopik83 = candidates.where(_isTopik83ActualSet).toList();
    // Actual TOPIK II sets can contain questions for multiple grades while the
    // set itself has one representative level. Keep TOPIK 83 eligible and let
    // the questions endpoint apply the selected grade filter.
    if (byLevel.isEmpty && actualTopik83.isEmpty) return null;
    final byId = <String, QuestionSet>{
      for (final set in byLevel) set.id: set,
      for (final set in actualTopik83) set.id: set,
    };
    candidates = byId.values.toList();
  }

  if (candidates.isEmpty) return fallbackId;
  int score(QuestionSet s) {
    final n = s.questionCount ?? s.questions.length;
    final isTopik102 = _isTopikRoundSet(s, 102);
    final isTopik83 = _isTopikRoundSet(s, 83);
    final isReal = _isActualSet(s);
    final isLevelSpecificPractice = s.id.startsWith('practice-') && s.level == level;
    return n +
        (isTopik102 ? 2000000 : 0) +
        (isTopik83 ? 1000000 : 0) +
        (isReal ? 500000 : 0) +
        (isLevelSpecificPractice ? 1000 : 0);
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
  return ref
      .read(questionSetsProvider)
      .maybeWhen(
        data: (sets) => resolvedPracticeSetId(
          sets: sets,
          section: section,
          fallbackId: fallbackId,
          level: level,
        ),
        orElse: () => fallbackId,
      );
}

bool _isActualSet(QuestionSet set) {
  if (set.examKind?.toLowerCase() == 'mock') return false;
  final haystack = '${set.id} ${set.title}'.toLowerCase();
  return haystack.contains('topik1-') ||
      haystack.contains('topik2-') ||
      haystack.contains('actual') ||
      haystack.contains('past') ||
      haystack.contains('real') ||
      haystack.contains('기출') ||
      haystack.contains('실전') ||
      haystack.contains('회');
}

bool _isTopikRoundSet(QuestionSet set, int round) {
  final haystack = '${set.id} ${set.title}'.toLowerCase();
  final hasRound = RegExp('(^|[^0-9])$round([^0-9]|\$)').hasMatch(haystack);
  return hasRound && (haystack.contains('topik') || haystack.contains('회'));
}

bool _isTopik83ActualSet(QuestionSet set) {
  return _isTopikRoundSet(set, 83) && _isActualSet(set);
}
