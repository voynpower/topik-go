import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';

class OfflineSummary {
  const OfflineSummary({
    required this.totalItems,
    required this.totalSizeMb,
    required this.categoryCounts,
  });

  final int totalItems;
  final double totalSizeMb;
  final Map<String, int> categoryCounts;

  factory OfflineSummary.fromJson(Map<String, dynamic> json) {
    return OfflineSummary(
      totalItems: _asInt(json['total_items']) ?? 0,
      totalSizeMb: _asDouble(json['total_size_mb']) ?? 0.0,
      categoryCounts: Map<String, int>.from(json['category_counts'] ?? {}),
    );
  }
}

class OfflineItem {
  const OfflineItem({
    required this.id,
    required this.category,
    required this.title,
    required this.downloadedAt,
    this.sizeMb,
  });

  final String id;
  final String category;
  final String title;
  final DateTime downloadedAt;
  final double? sizeMb;

  factory OfflineItem.fromJson(Map<String, dynamic> json) {
    return OfflineItem(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      downloadedAt: DateTime.parse(json['downloaded_at']),
      sizeMb: _asDouble(json['size_mb']),
    );
  }
}

class OfflineSyncStatus {
  const OfflineSyncStatus({
    required this.isSyncing,
    required this.lastSyncAt,
    this.progress,
  });

  final bool isSyncing;
  final DateTime? lastSyncAt;
  final double? progress;

  factory OfflineSyncStatus.fromJson(Map<String, dynamic> json) {
    return OfflineSyncStatus(
      isSyncing: json['is_syncing'] == true,
      lastSyncAt: json['last_sync_at'] != null 
          ? DateTime.parse(json['last_sync_at']) 
          : null,
      progress: _asDouble(json['progress']),
    );
  }
}

class OfflineRepository {
  const OfflineRepository(this._dio);

  final Dio _dio;

  Future<OfflineSummary> getSummary() async {
    final response = await _dio.get('/offline/summary');
    return OfflineSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OfflineItem>> getItems() async {
    final response = await _dio.get('/offline/items');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(OfflineItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> syncOfflineItems() async {
    await _dio.post('/offline/sync');
  }

  Future<OfflineSyncStatus> getSyncStatus() async {
    final response = await _dio.get('/offline/sync/status');
    return OfflineSyncStatus.fromJson(response.data as Map<String, dynamic>);
  }
}

final offlineRepositoryProvider = Provider<OfflineRepository>((ref) {
  return OfflineRepository(ref.watch(dioProvider));
});

final offlineSummaryProvider = FutureProvider<OfflineSummary>((ref) {
  return ref.watch(offlineRepositoryProvider).getSummary();
});

final offlineItemsProvider = FutureProvider<List<OfflineItem>>((ref) {
  return ref.watch(offlineRepositoryProvider).getItems();
});

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
