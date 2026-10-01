import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/grammar/data/grammar_repository.dart';
import 'package:topik_go/features/grammar/domain/ai_grammar_service.dart';

class UserGrammarState {
  const UserGrammarState({
    this.savedGrammars = const [],
  });

  final List<AiGrammarDetail> savedGrammars;

  bool isSaved(String pattern) {
    final clean = pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '');
    return savedGrammars.any((g) =>
        g.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '') == clean ||
        g.id == pattern);
  }

  /// OneGrammar 학습용 GrammarItem 목록으로 변환
  List<GrammarItem> toGrammarItems() {
    return savedGrammars.map((g) {
      return GrammarItem(
        id: g.id,
        pattern: g.pattern,
        description: '${g.meaning}\n${g.explanation}',
        examples: g.examples.map((e) => e.korean).toList(),
        tags: ['TOPIK II', g.category, 'AI 저장'],
        isDownloaded: false,
        isBookmarked: true,
        level: g.level,
      );
    }).toList();
  }
}

class UserGrammarNotifier extends Notifier<UserGrammarState> {
  static const _savedKey = 'user_saved_ai_grammars_v1';

  @override
  UserGrammarState build() {
    _loadFromPrefs();
    return const UserGrammarState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(raw);
        final list = decoded
            .whereType<Map<String, dynamic>>()
            .map(AiGrammarDetail.fromJson)
            .toList();
        state = UserGrammarState(savedGrammars: list);
      } catch (_) {}
    }
  }

  Future<void> _saveToPrefs(List<AiGrammarDetail> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_savedKey, raw);
  }

  Future<void> saveGrammar(AiGrammarDetail grammar) async {
    final updated = grammar.copyWith(isBookmarked: true);
    final list = List<AiGrammarDetail>.from(state.savedGrammars);

    final clean = grammar.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '');
    final index = list.indexWhere((g) =>
        g.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '') == clean ||
        g.id == grammar.id);

    if (index >= 0) {
      list[index] = updated;
    } else {
      list.insert(0, updated);
    }

    state = UserGrammarState(savedGrammars: list);
    await _saveToPrefs(list);

    // 백그라운드 동기화 및 프로바이더 갱신
    unawaited(() async {
      try {
        await ref.read(bookmarkRepositoryProvider).setGrammarBookmark(
              grammarId: grammar.id,
              bookmarked: true,
            );
      } catch (_) {}
      ref.invalidate(bookmarkedGrammarProvider);
      ref.invalidate(bookmarkSummaryProvider);
    }());
  }

  Future<void> removeGrammar(String pattern) async {
    final clean = pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '');
    final list = state.savedGrammars
        .where((g) =>
            g.pattern.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣]'), '') != clean &&
            g.id != pattern)
        .toList();

    state = UserGrammarState(savedGrammars: list);
    await _saveToPrefs(list);

    unawaited(() async {
      try {
        await ref.read(bookmarkRepositoryProvider).setGrammarBookmark(
              grammarId: pattern,
              bookmarked: false,
            );
      } catch (_) {}
      ref.invalidate(bookmarkedGrammarProvider);
      ref.invalidate(bookmarkSummaryProvider);
    }());
  }
}

final userGrammarProvider =
    NotifierProvider<UserGrammarNotifier, UserGrammarState>(() {
  return UserGrammarNotifier();
});
