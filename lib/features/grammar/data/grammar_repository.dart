import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';

class GrammarItem {
  const GrammarItem({
    required this.id,
    required this.pattern,
    required this.description,
    required this.examples,
    required this.tags,
    required this.isDownloaded,
  });

  final String id;
  final String pattern;
  final String description;
  final List<String> examples;
  final List<String> tags;
  final bool isDownloaded;

  factory GrammarItem.fromJson(Map<String, dynamic> json) {
    return GrammarItem(
      id: json['id']?.toString() ?? '',
      pattern: json['pattern']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      examples: _stringList(json['examples_json']),
      tags: _stringList(json['tags_json']),
      isDownloaded: _asBool(json['is_downloaded']),
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
  const GrammarQuery({this.q, this.page = 1, this.limit = 20});

  final String? q;
  final int page;
  final int limit;

  Map<String, Object> toQueryParameters() {
    return {
      if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
      'page': page,
      'limit': limit,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GrammarQuery &&
            other.q == q &&
            other.page == page &&
            other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(q, page, limit);
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
  if (value is List) {
    return value
        .map((item) => item is Map ? item.values.join(' / ') : item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  if (value == null) return const [];
  return [value.toString()];
}
