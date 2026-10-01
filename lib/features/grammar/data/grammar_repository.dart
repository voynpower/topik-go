import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_master.dart';

class GrammarItem {
  const GrammarItem({
    required this.id,
    required this.pattern,
    required this.description,
    required this.examples,
    required this.tags,
    required this.isDownloaded,
    required this.isBookmarked,
    this.level,
    this.category,
    this.meaningKo,
    this.meaningUz,
    this.meaningRu,
    this.meaningEn,
    this.explanationKo,
    this.explanationUz,
    this.explanationRu,
    this.explanationEn,
    this.conjugationRule,
    this.comparisons = const [],
    this.richExamples = const [],
    this.quizzes = const [],
  });

  final String id;
  final String pattern;
  final String description;
  final List<String> examples;
  final List<String> tags;
  final bool isDownloaded;
  final bool isBookmarked;
  final int? level;
  final String? category;
  final String? meaningKo;
  final String? meaningUz;
  final String? meaningRu;
  final String? meaningEn;
  final String? explanationKo;
  final String? explanationUz;
  final String? explanationRu;
  final String? explanationEn;
  final String? conjugationRule;
  final List<ConfusingGrammarComparison> comparisons;
  final List<MasterGrammarExample> richExamples;
  final List<MasterGrammarQuiz> quizzes;

  factory GrammarItem.fromJson(Map<String, dynamic> json) {
    final comparisons = (json['comparisons_json'] as List?)
            ?.map((c) => ConfusingGrammarComparison.fromJson(Map<String, dynamic>.from(c)))
            .toList() ??
        const <ConfusingGrammarComparison>[];

    final richExamples = (json['examples_json'] as List?)
            ?.map((e) {
              if (e is Map) return MasterGrammarExample.fromJson(Map<String, dynamic>.from(e));
              if (e is String) return MasterGrammarExample(korean: e);
              return null;
            })
            .whereType<MasterGrammarExample>()
            .toList() ??
        const <MasterGrammarExample>[];

    final quizzes = (json['quizzes_json'] as List?)
            ?.map((q) => MasterGrammarQuiz.fromJson(Map<String, dynamic>.from(q)))
            .toList() ??
        const <MasterGrammarQuiz>[];

    return GrammarItem(
      id: json['id']?.toString() ?? '',
      pattern: _firstString(json, const ['pattern', 'title', 'grammar']) ?? '',
      description:
          _firstString(json, const ['description', 'meaning_ko', 'meaning', 'explanation']) ??
          '',
      examples: _stringList(json['examples_json'] ?? json['examples']),
      tags: _stringList(json['tags_json'] ?? json['tags']),
      isDownloaded: _asBool(json['is_downloaded']),
      isBookmarked: _asBool(json['is_bookmarked'] ?? json['bookmarked']),
      level: _asInt(json['level']),
      category: json['category']?.toString(),
      meaningKo: json['meaning_ko']?.toString(),
      meaningUz: json['meaning_uz']?.toString(),
      meaningRu: json['meaning_ru']?.toString(),
      meaningEn: json['meaning_en']?.toString(),
      explanationKo: json['explanation_ko']?.toString(),
      explanationUz: json['explanation_uz']?.toString(),
      explanationRu: json['explanation_ru']?.toString(),
      explanationEn: json['explanation_en']?.toString(),
      conjugationRule: json['conjugation_rule']?.toString(),
      comparisons: comparisons,
      richExamples: richExamples,
      quizzes: quizzes,
    );
  }

  String getMeaning(String langCode) {
    if (langCode == 'ko' && (meaningKo?.isNotEmpty ?? false)) return meaningKo!;
    if (langCode == 'uz' && (meaningUz?.isNotEmpty ?? false)) return meaningUz!;
    if (langCode == 'ru' && (meaningRu?.isNotEmpty ?? false)) return meaningRu!;
    if (langCode == 'en' && (meaningEn?.isNotEmpty ?? false)) return meaningEn!;
    if (langCode != 'ko' && (meaningEn?.isNotEmpty ?? false)) return meaningEn!;
    if (meaningKo?.isNotEmpty ?? false) return meaningKo!;
    return description;
  }

  String getExplanation(String langCode) {
    if (langCode == 'ko' && (explanationKo?.isNotEmpty ?? false)) return explanationKo!;
    if (langCode == 'uz' && (explanationUz?.isNotEmpty ?? false)) return explanationUz!;
    if (langCode == 'ru' && (explanationRu?.isNotEmpty ?? false)) return explanationRu!;
    if (langCode == 'en' && (explanationEn?.isNotEmpty ?? false)) return explanationEn!;
    if (langCode != 'ko' && (explanationEn?.isNotEmpty ?? false)) return explanationEn!;
    if (explanationKo?.isNotEmpty ?? false) return explanationKo!;
    return description;
  }

  MasterGrammarItem toMasterGrammarItem() {
    return MasterGrammarItem(
      id: id,
      pattern: pattern,
      level: level ?? 1,
      category: category ?? (tags.isNotEmpty ? tags.first : '기타'),
      meaningKo: meaningKo ?? description,
      meaningUz: meaningUz,
      meaningRu: meaningRu,
      meaningEn: meaningEn,
      explanationKo: explanationKo ?? description,
      explanationUz: explanationUz,
      explanationRu: explanationRu,
      explanationEn: explanationEn,
      conjugationRule: conjugationRule ?? pattern,
      comparisons: comparisons,
      examples: richExamples.isNotEmpty
          ? richExamples
          : examples.map((e) => MasterGrammarExample(korean: e)).toList(),
      quizzes: quizzes,
      tags: tags,
    );
  }
}

class GrammarPage {
  const GrammarPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<GrammarItem> items;
  final int page;
  final int limit;
  final int total;

  factory GrammarPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];

    return GrammarPage(
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(GrammarItem.fromJson)
                .toList()
          : const [],
      page: _asInt(json['page']) ?? 1,
      limit: _asInt(json['limit']) ?? 20,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class GrammarQuery {
  const GrammarQuery({this.level, this.category, this.q, this.page = 1, this.limit = 20});

  final int? level;
  final String? category;
  final String? q;
  final int page;
  final int limit;

  Map<String, Object> toQueryParameters() {
    return {
      'level': ?level,
      if (category != null && category!.trim().isNotEmpty) 'category': category!.trim(),
      if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
      'page': page,
      'limit': limit,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GrammarQuery &&
            other.level == level &&
            other.category == category &&
            other.q == q &&
            other.page == page &&
            other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(level, category, q, page, limit);
}

class GrammarRepository {
  const GrammarRepository(this._dio);

  final Dio _dio;

  Future<GrammarPage> getGrammar(GrammarQuery query) async {
    final response = await _dio.get(
      '/grammar',
      queryParameters: query.toQueryParameters(),
    );
    return GrammarPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GrammarItem> getGrammarItem(String id) async {
    final response = await _dio.get('/grammar/$id');
    return GrammarItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> bookmarkGrammar(String id) async {
    await _dio.patch('/grammar/$id/bookmark');
  }

  Future<void> setGrammarBookmark({
    required String id,
    required bool bookmarked,
  }) async {
    await _dio.patch(
      '/bookmarks/grammar/$id',
      data: {'bookmarked': bookmarked},
    );
  }

  Future<GrammarItem> downloadGrammar(String id) async {
    final response = await _dio.post('/grammar/$id/download');
    return GrammarItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GrammarItem> removeGrammarDownload(String id) async {
    final response = await _dio.delete('/grammar/$id/download');
    return GrammarItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GrammarItem> createGrammar({
    required String pattern,
    required String description,
    required List<String> examples,
    required List<String> tags,
  }) async {
    final response = await _dio.post(
      '/grammar',
      data: {
        'pattern': pattern,
        'description': description,
        'examples_json': examples,
        'tags_json': tags,
      },
    );
    return GrammarItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GrammarItem> updateGrammar(
    String id, {
    String? pattern,
    String? description,
    List<String>? examples,
    List<String>? tags,
  }) async {
    final response = await _dio.patch(
      '/grammar/$id',
      data: {
        'pattern': ?pattern,
        'description': ?description,
        'examples_json': ?examples,
        'tags_json': ?tags,
      },
    );
    return GrammarItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGrammar(String id) async {
    await _dio.delete('/grammar/$id');
  }
}

final grammarRepositoryProvider = Provider<GrammarRepository>((ref) {
  return GrammarRepository(ref.watch(dioProvider));
});

final grammarProvider = FutureProvider.family<GrammarPage, GrammarQuery>((
  ref,
  query,
) {
  return ref.watch(grammarRepositoryProvider).getGrammar(query);
});

final grammarItemProvider = FutureProvider.family<GrammarItem, String>((
  ref,
  id,
) {
  return ref.watch(grammarRepositoryProvider).getGrammarItem(id);
});

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is num) return value.toInt() == 1;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

List<String> _stringList(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const [];
    try {
      return _stringList(jsonDecode(trimmed));
    } catch (_) {
      return [trimmed];
    }
  }

  if (value is List) {
    return value
        .map(_stringListItem)
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  if (value == null) return const [];
  return [value.toString()];
}

String _stringListItem(Object? item) {
  if (item is Map) {
    final ko = (item['korean'] ?? item['ko'])?.toString().trim();
    final en = (item['english'] ?? item['en'])?.toString().trim();
    final uz = (item['uzbek'] ?? item['uz'])?.toString().trim();
    final ru = (item['russian'] ?? item['ru'])?.toString().trim();

    if (ko != null && ko.isNotEmpty) {
      if (en != null && en.isNotEmpty) return '$ko\n$en';
      if (uz != null && uz.isNotEmpty) return '$ko\n$uz';
      if (ru != null && ru.isNotEmpty) return '$ko\n$ru';
      return ko;
    }
    if (en != null && en.isNotEmpty) return en;
    if (uz != null && uz.isNotEmpty) return uz;
    if (ru != null && ru.isNotEmpty) return ru;
    return item['text']?.toString() ?? '';
  }
  return item?.toString() ?? '';
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}
