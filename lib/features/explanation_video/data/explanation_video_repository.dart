import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';

class ExplanationVideo {
  const ExplanationVideo({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.durationSeconds,
    this.thumbnailUrl,
    this.description,
    this.questionId,
    this.setId,
    this.section,
    this.level,
    this.targetTitle,
    this.targetDescription,
    this.viewCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String videoUrl;
  final int durationSeconds;
  final String? thumbnailUrl;
  final String? description;
  final String? questionId;
  final String? setId;
  final String? section;
  final int? level;
  final String? targetTitle;
  final String? targetDescription;
  final int viewCount;
  final DateTime? createdAt;

  factory ExplanationVideo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ExplanationVideo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      durationSeconds: _asInt(json['duration_seconds']) ?? 0,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      description: json['description']?.toString(),
      questionId: json['question_id']?.toString(),
      setId: json['set_id']?.toString(),
      section: json['section']?.toString(),
      level: _asInt(json['level']),
      targetTitle: json['target_title']?.toString(),
      targetDescription: json['target_description']?.toString(),
      viewCount: _asInt(json['view_count']) ?? 0,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'video_url': videoUrl,
      'duration_seconds': durationSeconds,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (description != null) 'description': description,
      if (questionId != null) 'question_id': questionId,
      if (setId != null) 'set_id': setId,
      if (section != null) 'section': section,
      if (level != null) 'level': level,
    };
  }
}

class ExplanationVideoQuery {
  const ExplanationVideoQuery({
    this.section,
    this.level,
    this.questionId,
    this.setId,
    this.page = 1,
    this.limit = 20,
  });

  final String? section;
  final int? level;
  final String? questionId;
  final String? setId;
  final int page;
  final int limit;

  Map<String, Object> toQueryParameters() {
    return {
      if (section != null && section!.isNotEmpty) 'section': section!,
      'level': ?level,
      if (questionId != null && questionId!.isNotEmpty)
        'question_id': questionId!,
      if (setId != null && setId!.isNotEmpty) 'set_id': setId!,
      'page': page,
      'limit': limit,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ExplanationVideoQuery &&
        other.section == section &&
        other.level == level &&
        other.questionId == questionId &&
        other.setId == setId &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      Object.hash(section, level, questionId, setId, page, limit);
}

class ExplanationVideoRepository {
  const ExplanationVideoRepository(this._dio);

  final Dio _dio;

  Future<List<ExplanationVideo>> getVideos([
    ExplanationVideoQuery query = const ExplanationVideoQuery(),
  ]) async {
    final response = await _dio.get(
      '/explanation-videos',
      queryParameters: query.toQueryParameters(),
    );
    return _videosFromResponse(response.data);
  }

  Future<List<ExplanationVideo>> getRecommendedVideos() async {
    final response = await _dio.get('/explanation-videos/recommended');
    return _videosFromResponse(response.data);
  }

  Future<ExplanationVideo> getVideo(String id) async {
    final response = await _dio.get('/explanation-videos/$id');
    return ExplanationVideo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExplanationVideo> createVideo(ExplanationVideo video) async {
    final response = await _dio.post(
      '/explanation-videos',
      data: video.toJson(),
    );
    return ExplanationVideo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteVideo(String id) async {
    await _dio.delete('/explanation-videos/$id');
  }
}

List<ExplanationVideo> _videosFromResponse(Object? data) {
  final rawItems = data is Map<String, dynamic> ? data['items'] : data;
  if (rawItems is! List) return const [];
  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(ExplanationVideo.fromJson)
      .toList();
}

final explanationVideoRepositoryProvider = Provider<ExplanationVideoRepository>(
  (ref) {
    return ExplanationVideoRepository(ref.watch(dioProvider));
  },
);

final explanationVideosProvider = FutureProvider<List<ExplanationVideo>>((ref) {
  return ref.watch(explanationVideoRepositoryProvider).getVideos();
});

final recommendedVideosProvider = FutureProvider<List<ExplanationVideo>>((ref) {
  return ref.watch(explanationVideoRepositoryProvider).getRecommendedVideos();
});

final explanationVideosForQueryProvider =
    FutureProvider.family<List<ExplanationVideo>, ExplanationVideoQuery>((
      ref,
      query,
    ) {
      return ref.watch(explanationVideoRepositoryProvider).getVideos(query);
    });

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
