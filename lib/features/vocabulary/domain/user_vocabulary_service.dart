import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/features/bookmarks/data/bookmark_repository.dart';
import 'package:topik_go/features/vocabulary/data/vocabulary_repository.dart';

class EditedWordData {
  const EditedWordData({
    required this.word,
    required this.meaning,
  });

  final String word;
  final String meaning;

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
      };

  factory EditedWordData.fromJson(Map<String, dynamic> json) => EditedWordData(
        word: json['word']?.toString() ?? '',
        meaning: json['meaning']?.toString() ?? '',
      );
}

class UserVocabularyOverrideState {
  const UserVocabularyOverrideState({
    this.deletedWordIds = const {},
    this.editedWords = const {},
    this.customWords = const [],
  });

  final Set<String> deletedWordIds;
  final Map<String, EditedWordData> editedWords;
  final List<VocabularyItem> customWords;

  bool isDeleted(String id) => deletedWordIds.contains(id);

  EditedWordData? getEdit(String id) => editedWords[id];

  List<VocabularyItem> applyOverrides(List<VocabularyItem> items) {
    // 1. Exclude deleted words
    final notDeleted = items.where((item) => !isDeleted(item.id)).toList();

    // 2. Apply word and meaning edits
    final edited = notDeleted.map((item) {
      final edit = getEdit(item.id);
      if (edit != null) {
        return item.copyWith(
          word: edit.word.isNotEmpty ? edit.word : item.word,
          meaningKo: edit.meaning.isNotEmpty ? edit.meaning : item.meaningKo,
          meaningUserLang:
              edit.meaning.isNotEmpty ? edit.meaning : item.meaningUserLang,
        );
      }
      return item;
    }).toList();

    // 3. Prepend custom created words (that aren't deleted and not already in list)
    final existingIds = edited.map((e) => e.id).toSet();
    final existingWords = edited.map((e) => e.word.trim()).toSet();
    final nonDeletedCustom = customWords
        .where((c) =>
            !isDeleted(c.id) &&
            !existingIds.contains(c.id) &&
            !existingWords.contains(c.word.trim()))
        .toList();

    return [...nonDeletedCustom, ...edited];
  }
}

class UserVocabularyNotifier extends Notifier<UserVocabularyOverrideState> {
  static const _deletedKey = 'user_deleted_word_ids';
  static const _editedKey = 'user_edited_words_map';
  static const _customKey = 'user_custom_words_list';

  @override
  UserVocabularyOverrideState build() {
    _loadFromPrefs();
    return const UserVocabularyOverrideState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedList = prefs.getStringList(_deletedKey) ?? [];
    final rawEdited = prefs.getString(_editedKey);
    final rawCustom = prefs.getString(_customKey);

    final deletedSet = deletedList.toSet();
    final editedMap = <String, EditedWordData>{};
    if (rawEdited != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(rawEdited);
        decoded.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            editedMap[key] = EditedWordData.fromJson(val);
          }
        });
      } catch (_) {}
    }

    final customList = <VocabularyItem>[];
    if (rawCustom != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rawCustom);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            customList.add(VocabularyItem.fromJson(item));
          }
        }
      } catch (_) {}
    }

    state = UserVocabularyOverrideState(
      deletedWordIds: deletedSet,
      editedWords: editedMap,
      customWords: customList,
    );
  }

  Future<void> deleteWord(String id) async {
    final nextDeleted = Set<String>.from(state.deletedWordIds)..add(id);
    final nextEdited = Map<String, EditedWordData>.from(state.editedWords)..remove(id);
    final nextCustom = state.customWords.where((c) => c.id != id).toList();

    state = UserVocabularyOverrideState(
      deletedWordIds: nextDeleted,
      editedWords: nextEdited,
      customWords: nextCustom,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_deletedKey, nextDeleted.toList());
    await prefs.setString(
      _editedKey,
      jsonEncode(nextEdited.map((k, v) => MapEntry(k, v.toJson()))),
    );
    await prefs.setString(
      _customKey,
      jsonEncode(nextCustom.map((e) => e.toJson()).toList()),
    );

    // Background sync: attempt backend delete & unbookmark
    unawaited(() async {
      try {
        await ref.read(vocabularyRepositoryProvider).deleteVocabulary(id);
      } catch (_) {
        try {
          await ref.read(bookmarkRepositoryProvider).setVocabularyBookmark(
                vocabularyId: id,
                bookmarked: false,
              );
        } catch (_) {}
      }
    }());
  }

  Future<void> editWord(
    String id, {
    required String word,
    required String meaning,
  }) async {
    final nextEdited = Map<String, EditedWordData>.from(state.editedWords);
    nextEdited[id] = EditedWordData(word: word, meaning: meaning);

    // Also update customWords if this was a custom word
    final nextCustom = state.customWords.map((c) {
      if (c.id == id) {
        return c.copyWith(
          word: word,
          meaningKo: meaning,
          meaningUserLang: meaning,
        );
      }
      return c;
    }).toList();

    state = UserVocabularyOverrideState(
      deletedWordIds: state.deletedWordIds,
      editedWords: nextEdited,
      customWords: nextCustom,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _editedKey,
      jsonEncode(nextEdited.map((k, v) => MapEntry(k, v.toJson()))),
    );
    await prefs.setString(
      _customKey,
      jsonEncode(nextCustom.map((e) => e.toJson()).toList()),
    );

    // Background sync: attempt backend update
    unawaited(() async {
      try {
        await ref.read(vocabularyRepositoryProvider).updateVocabulary(
              id,
              word: word,
              meaningKo: meaning,
              meaningUserLang: meaning,
            );
      } catch (_) {}
      try {
        await ref.read(bookmarkRepositoryProvider).setVocabularyBookmark(
              vocabularyId: id,
              bookmarked: true,
              meaningUserLang: meaning,
            );
      } catch (_) {}
    }());
  }

  Future<void> addCustomWord({
    required String word,
    required String meaning,
  }) async {
    final newItem = VocabularyItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      word: word,
      meaningKo: meaning,
      meaningUserLang: meaning,
      level: 3,
      isDownloaded: false,
      isBookmarked: true,
    );

    final nextCustom = [newItem, ...state.customWords];
    state = UserVocabularyOverrideState(
      deletedWordIds: state.deletedWordIds,
      editedWords: state.editedWords,
      customWords: nextCustom,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customKey,
      jsonEncode(nextCustom.map((e) => e.toJson()).toList()),
    );

    // Background sync
    unawaited(() async {
      try {
        await ref.read(bookmarkRepositoryProvider).addVocabularyByWord(
              word: word,
              meaningUserLang: meaning,
              level: 3,
            );
      } catch (_) {}
    }());
  }

  Future<void> registerBookmarkedWord(VocabularyItem item) async {
    final nextDeleted = Set<String>.from(state.deletedWordIds)..remove(item.id);

    final existsInCustom = state.customWords.any((c) => c.id == item.id || c.word.trim() == item.word.trim());
    final nextCustom = existsInCustom
        ? state.customWords.map((c) {
            if (c.id == item.id || c.word.trim() == item.word.trim()) {
              return item.copyWith(isBookmarked: true);
            }
            return c;
          }).toList()
        : [item.copyWith(isBookmarked: true), ...state.customWords];

    state = UserVocabularyOverrideState(
      deletedWordIds: nextDeleted,
      editedWords: state.editedWords,
      customWords: nextCustom,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_deletedKey, nextDeleted.toList());
    await prefs.setString(
      _customKey,
      jsonEncode(nextCustom.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removeBookmarkedWord(String id, [String? word]) async {
    final nextCustom = state.customWords.where((c) {
      if (c.id == id) return false;
      if (word != null && word.trim().isNotEmpty && c.word.trim() == word.trim()) return false;
      return true;
    }).toList();

    state = UserVocabularyOverrideState(
      deletedWordIds: state.deletedWordIds,
      editedWords: state.editedWords,
      customWords: nextCustom,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customKey,
      jsonEncode(nextCustom.map((e) => e.toJson()).toList()),
    );
  }
}

final userVocabularyOverrideProvider =
    NotifierProvider<UserVocabularyNotifier, UserVocabularyOverrideState>(() {
  return UserVocabularyNotifier();
});
