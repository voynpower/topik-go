import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';

class TopikExamSchedule {
  const TopikExamSchedule({
    required this.id,
    required this.title,
    required this.examDate,
    this.registrationStartDate,
    this.registrationEndDate,
    this.resultDate,
    this.isCurrent = false,
  });

  final String id;
  final String title;
  final DateTime examDate;
  final DateTime? registrationStartDate;
  final DateTime? registrationEndDate;
  final DateTime? resultDate;
  final bool isCurrent;

  factory TopikExamSchedule.fromJson(Map<String, dynamic> json) {
    return TopikExamSchedule(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      examDate: DateTime.parse(json['exam_date']),
      registrationStartDate: json['registration_start_date'] != null
          ? DateTime.parse(json['registration_start_date'])
          : null,
      registrationEndDate: json['registration_end_date'] != null
          ? DateTime.parse(json['registration_end_date'])
          : null,
      resultDate: json['result_date'] != null
          ? DateTime.parse(json['result_date'])
          : null,
      isCurrent: json['is_current'] == true || json['is_current'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'exam_date': examDate.toIso8601String(),
      if (registrationStartDate != null)
        'registration_start_date': registrationStartDate!.toIso8601String(),
      if (registrationEndDate != null)
        'registration_end_date': registrationEndDate!.toIso8601String(),
      if (resultDate != null)
        'result_date': resultDate!.toIso8601String(),
      'is_current': isCurrent,
    };
  }
}

class ExamScheduleRepository {
  const ExamScheduleRepository(this._dio);

  final Dio _dio;

  Future<List<TopikExamSchedule>> getSchedules() async {
    final response = await _dio.get('/topik-exam-schedules');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(TopikExamSchedule.fromJson)
          .toList();
    }
    return [];
  }

  Future<TopikExamSchedule> createSchedule(TopikExamSchedule schedule) async {
    final response = await _dio.post(
      '/topik-exam-schedules',
      data: schedule.toJson(),
    );
    return TopikExamSchedule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TopikExamSchedule?> getNextSchedule() async {
    try {
      final response = await _dio.get('/topik-exam-schedules/next');
      if (response.data == null) return null;
      return TopikExamSchedule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching next schedule: $e');
      return null;
    }
  }

  Future<TopikExamSchedule> updateSchedule(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.patch(
      '/topik-exam-schedules/$id',
      data: updates,
    );
    return TopikExamSchedule.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete('/topik-exam-schedules/$id');
  }
}

final examScheduleRepositoryProvider = Provider<ExamScheduleRepository>((ref) {
  return ExamScheduleRepository(ref.watch(dioProvider));
});

final examSchedulesProvider = FutureProvider<List<TopikExamSchedule>>((ref) {
  return ref.watch(examScheduleRepositoryProvider).getSchedules();
});

final nextExamScheduleProvider = FutureProvider<TopikExamSchedule?>((ref) {
  return ref.watch(examScheduleRepositoryProvider).getNextSchedule();
});
