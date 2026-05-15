import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';

class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.word,
    required this.meaningKo,
    required this.level,
    required this.isDownloaded,
    this.meaningUserLang,
    this.ttsUrl,
  });

  final String id;
  final String word;
  final String meaningKo;
  final int level;
  final bool isDownloaded;
  final String? meaningUserLang;
  final String? ttsUrl;

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      meaningKo: json['meaning_ko']?.toString() ?? '',
      meaningUserLang: json['meaning_user_lang']?.toString(),
      level: _asInt(json['level']) ?? 0,
      ttsUrl: json['tts_url']?.toString(),
      isDownloaded: _asBool(json['is_downloaded']),
    );
  }
}

class VocabularyPage {
  const VocabularyPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<VocabularyItem> items;
  final int page;
  final int limit;
  final int total;

  factory VocabularyPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];

    return VocabularyPage(
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(VocabularyItem.fromJson)
                .toList()
          : const [],
      page: _asInt(json['page']) ?? 1,
      limit: _asInt(json['limit']) ?? 20,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class VocabularyQuery {
  const VocabularyQuery({this.level, this.q, this.page = 1, this.limit = 20});

  final int? level;
  final String? q;
  final int page;
  final int limit;

  Map<String, Object> toQueryParameters() {
    return {
      if (level != null) 'level': level!,
      if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
      'page': page,
      'limit': limit,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VocabularyQuery &&
            other.level == level &&
            other.q == q &&
            other.page == page &&
            other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(level, q, page, limit);
}

class VocabularyRepository {
  const VocabularyRepository(this._dio);

  final Dio _dio;

  Future<VocabularyPage> getVocabulary(VocabularyQuery query) async {
    final response = await _dio.get(
      '/vocabulary',
      queryParameters: query.toQueryParameters(),
    );
    return VocabularyPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VocabularyItem> getVocabularyItem(String id) async {
    final response = await _dio.get('/vocabulary/$id');
    return VocabularyItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> bookmarkVocabulary(String id) async {
    await _dio.patch('/vocabulary/$id/bookmark');
  }

  Future<VocabularyItem> downloadVocabulary(String id) async {
    final response = await _dio.post('/vocabulary/$id/download');
    return VocabularyItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VocabularyItem> removeVocabularyDownload(String id) async {
    final response = await _dio.delete('/vocabulary/$id/download');
    return VocabularyItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VocabularyItem> createVocabulary({
    required String word,
    required String meaningKo,
    required int level,
    String? meaningUserLang,
    String? ttsUrl,
  }) async {
    final response = await _dio.post(
      '/vocabulary',
      data: {
        'word': word,
        'meaning_ko': meaningKo,
        'level': level,
        if (meaningUserLang != null) 'meaning_user_lang': meaningUserLang,
        if (ttsUrl != null) 'tts_url': ttsUrl,
      },
    );
    return VocabularyItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VocabularyItem> updateVocabulary(
    String id, {
    String? word,
    String? meaningKo,
    int? level,
    String? meaningUserLang,
    String? ttsUrl,
  }) async {
    final response = await _dio.patch(
      '/vocabulary/$id',
      data: {
        if (word != null) 'word': word,
        if (meaningKo != null) 'meaning_ko': meaningKo,
        if (level != null) 'level': level,
        if (meaningUserLang != null) 'meaning_user_lang': meaningUserLang,
        if (ttsUrl != null) 'tts_url': ttsUrl,
      },
    );
    return VocabularyItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteVocabulary(String id) async {
    await _dio.delete('/vocabulary/$id');
  }
}

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return VocabularyRepository(ref.watch(dioProvider));
});

final vocabularyProvider =
    FutureProvider.family<VocabularyPage, VocabularyQuery>((ref, query) {
      return ref.watch(vocabularyRepositoryProvider).getVocabulary(query);
    });

final vocabularyItemProvider = FutureProvider.family<VocabularyItem, String>((
  ref,
  id,
) {
  return ref.watch(vocabularyRepositoryProvider).getVocabularyItem(id);
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
