import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_dataset.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';
import 'package:topik_go/features/grammar/domain/grammar_study_models.dart';
import 'package:topik_go/features/grammar/domain/user_grammar_service.dart';

class GrammarFilterParams {
  const GrammarFilterParams({
    this.searchQuery = '',
    this.levelGroup = GrammarLevelGroup.all,
    this.category = GrammarCategoryType.all,
    this.targetLang = 'ko',
  });

  final String searchQuery;
  final GrammarLevelGroup levelGroup;
  final GrammarCategoryType category;
  final String targetLang;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrammarFilterParams &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          levelGroup == other.levelGroup &&
          category == other.category &&
          targetLang == other.targetLang;

  @override
  int get hashCode => Object.hash(searchQuery, levelGroup, category, targetLang);
}

class KoreanGrammarService {
  static List<MasterGrammarItem> getAllGrammars() {
    return kMasterGrammarList;
  }

  static MasterGrammarItem? findByPatternOrId(String query) {
    if (query.trim().isEmpty) return null;
    final lowerQ = query.trim().toLowerCase();
    final clean = query.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '').toLowerCase();

    for (final item in kMasterGrammarList) {
      if (item.id.toLowerCase() == lowerQ) return item;
      final cleanPattern = item.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '').toLowerCase();
      if (cleanPattern == clean) return item;
    }

    // Partial contains match fallback (matches id or pattern)
    for (final item in kMasterGrammarList) {
      if (item.id.toLowerCase().contains(lowerQ) || lowerQ.contains(item.id.toLowerCase())) {
        return item;
      }
      final cleanPattern = item.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '').toLowerCase();
      if (clean.isNotEmpty && (cleanPattern.contains(clean) || clean.contains(cleanPattern))) {
        return item;
      }
    }
    return null;
  }

  static List<MasterGrammarItem> filterGrammars({
    required List<MasterGrammarItem> allItems,
    required GrammarFilterParams params,
    required Set<String> savedPatterns,
  }) {
    return allItems.where((item) {
      // 1. Level Group Filter
      if (params.levelGroup == GrammarLevelGroup.saved) {
        final clean = item.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '');
        final isSaved = savedPatterns.any((p) =>
            p.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '') == clean ||
            p == item.id);
        if (!isSaved) return false;
      } else if (params.levelGroup != GrammarLevelGroup.all) {
        if (item.levelGroup != params.levelGroup) return false;
      }

      // 2. Category Filter
      if (params.category != GrammarCategoryType.all) {
        final dummyItem = GrammarItem(
          id: item.id,
          pattern: item.pattern,
          description: item.meaningKo,
          examples: item.examples.map((e) => e.korean).toList(),
          tags: [item.category, ...item.tags],
          isDownloaded: false,
          isBookmarked: false,
          level: item.level,
        );
        if (!GrammarCategory.matches(dummyItem, params.category)) {
          return false;
        }
      }

      // 3. Search Query (supports Korean pattern, meaning, Uzbek, Russian, English, tags)
      final q = params.searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final cleanQ = q.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '');
        final cleanPattern = item.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '').toLowerCase();

        final matchesPattern = cleanPattern.contains(cleanQ) || item.pattern.toLowerCase().contains(q);
        final matchesKo = item.meaningKo.toLowerCase().contains(q) || item.explanationKo.toLowerCase().contains(q);
        final matchesUz = (item.meaningUz?.toLowerCase().contains(q) ?? false) ||
            (item.explanationUz?.toLowerCase().contains(q) ?? false);
        final matchesRu = (item.meaningRu?.toLowerCase().contains(q) ?? false) ||
            (item.explanationRu?.toLowerCase().contains(q) ?? false);
        final matchesEn = (item.meaningEn?.toLowerCase().contains(q) ?? false) ||
            (item.explanationEn?.toLowerCase().contains(q) ?? false);
        final matchesTags = item.tags.any((t) => t.toLowerCase().contains(q));

        if (!matchesPattern && !matchesKo && !matchesUz && !matchesRu && !matchesEn && !matchesTags) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

final masterGrammarListProvider = Provider<List<MasterGrammarItem>>((ref) {
  final localList = KoreanGrammarService.getAllGrammars();
  final serverPageAsync = ref.watch(grammarProvider(const GrammarQuery(page: 1, limit: 100)));
  final serverItems = serverPageAsync.asData?.value.items ?? const <GrammarItem>[];

  if (serverItems.isEmpty) {
    return localList;
  }

  final map = <String, MasterGrammarItem>{};
  for (final local in localList) {
    map[local.pattern] = local;
  }
  for (final server in serverItems) {
    final existing = map[server.pattern];
    if (existing == null) {
      map[server.pattern] = server.toMasterGrammarItem();
    } else {
      map[server.pattern] = MasterGrammarItem(
        id: server.id.isNotEmpty ? server.id : existing.id,
        pattern: existing.pattern,
        level: server.level ?? existing.level,
        category: (server.category != null && server.category != '기타')
            ? server.category!
            : existing.category,
        meaningKo: server.meaningKo ?? existing.meaningKo,
        meaningUz: server.meaningUz ?? existing.meaningUz,
        meaningRu: server.meaningRu ?? existing.meaningRu,
        meaningEn: server.meaningEn ?? existing.meaningEn,
        explanationKo: server.explanationKo ?? existing.explanationKo,
        explanationUz: server.explanationUz ?? existing.explanationUz,
        explanationRu: server.explanationRu ?? existing.explanationRu,
        explanationEn: server.explanationEn ?? existing.explanationEn,
        conjugationRule: (server.conjugationRule != null && server.conjugationRule!.isNotEmpty)
            ? server.conjugationRule!
            : existing.conjugationRule,
        comparisons: server.comparisons.isNotEmpty ? server.comparisons : existing.comparisons,
        examples: server.richExamples.isNotEmpty ? server.richExamples : existing.examples,
        quizzes: server.quizzes.isNotEmpty ? server.quizzes : existing.quizzes,
        tags: {...existing.tags, ...server.tags}.toList(),
      );
    }
  }

  return map.values.toList();
});

final filteredMasterGrammarProvider =
    Provider.family<List<MasterGrammarItem>, GrammarFilterParams>((ref, params) {
  final allGrammars = ref.watch(masterGrammarListProvider);
  final userGrammarState = ref.watch(userGrammarProvider);
  final savedPatterns = userGrammarState.savedGrammars.map((g) => g.pattern).toSet();

  return KoreanGrammarService.filterGrammars(
    allItems: allGrammars,
    params: params,
    savedPatterns: savedPatterns,
  );
});

final masterGrammarDetailProvider =
    Provider.family<MasterGrammarItem?, String>((ref, idOrPattern) {
  final all = ref.watch(masterGrammarListProvider);
  for (final item in all) {
    if (item.id == idOrPattern || item.pattern == idOrPattern) return item;
  }
  return KoreanGrammarService.findByPatternOrId(idOrPattern);
});
