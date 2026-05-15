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
    this.viewCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String videoUrl;
  final int durationSeconds;
  final String? thumbnailUrl;
  final String? description;
  final int viewCount;
  final DateTime? createdAt;

  factory ExplanationVideo.fromJson(Map<String, dynamic> json) {
    return ExplanationVideo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      durationSeconds: _asInt(json['duration_seconds']) ?? 0,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      description: json['description']?.toString(),
      viewCount: _asInt(json['view_count']) ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'video_url': videoUrl,
      'duration_seconds': durationSeconds,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (description != null) 'description': description,
    };
  }
}

class ExplanationVideoRepository {
  const ExplanationVideoRepository(this._dio);

  final Dio _dio;

  Future<List<ExplanationVideo>> getVideos() async {
    final response = await _dio.get('/explanation-videos');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ExplanationVideo.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ExplanationVideo>> getRecommendedVideos() async {
    final response = await _dio.get('/explanation-videos/recommended');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ExplanationVideo.fromJson)
          .toList();
    }
    return [];
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

final explanationVideoRepositoryProvider = Provider<ExplanationVideoRepository>((ref) {
  return ExplanationVideoRepository(ref.watch(dioProvider));
});

final explanationVideosProvider = FutureProvider<List<ExplanationVideo>>((ref) {
  return ref.watch(explanationVideoRepositoryProvider).getVideos();
});

final recommendedVideosProvider = FutureProvider<List<ExplanationVideo>>((ref) {
  return ref.watch(explanationVideoRepositoryProvider).getRecommendedVideos();
});

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
