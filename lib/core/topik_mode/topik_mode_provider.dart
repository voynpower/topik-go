import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';

enum TopikMode {
  topik1,
  topik2;

  String get label => this == TopikMode.topik1 ? 'TOPIK I' : 'TOPIK II';
  String get shortLabel => this == TopikMode.topik1 ? 'I' : 'II';
  String get subLabel =>
      this == TopikMode.topik1 ? '초급 (1~2급)' : '중·고급 (3~6급)';
  String get levelRangeLabel => this == TopikMode.topik1 ? '1~2급' : '3~6급';

  bool get isTopik1 => this == TopikMode.topik1;
  bool get isTopik2 => this == TopikMode.topik2;

  bool get hasWriting => this == TopikMode.topik2;
  int get durationMinutes => this == TopikMode.topik1 ? 100 : 180;
  int get durationSeconds => durationMinutes * 60;

  int get totalQuestions => this == TopikMode.topik1 ? 70 : 104;
  int get listeningCount => this == TopikMode.topik1 ? 30 : 50;
  int get readingCount => this == TopikMode.topik1 ? 40 : 50;
  int get writingCount => this == TopikMode.topik1 ? 0 : 4;

  int get maxScore => this == TopikMode.topik1 ? 200 : 300;

  static TopikMode fromString(String? value) {
    if (value == 'topik1') return TopikMode.topik1;
    if (value == 'topik2') return TopikMode.topik2;
    return TopikMode.topik2;
  }
}

class TopikModeNotifier extends Notifier<TopikMode> {
  @override
  TopikMode build() {
    _init();
    return TopikMode.topik2;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(PrefsKeys.activeTopikMode);
    if (savedMode != null && savedMode.isNotEmpty) {
      state = TopikMode.fromString(savedMode);
      return;
    }

    final targetLevel = prefs.getInt(PrefsKeys.targetTopikLevel);
    if (targetLevel != null) {
      state = targetLevel <= 2 ? TopikMode.topik1 : TopikMode.topik2;
    } else {
      state = TopikMode.topik2;
    }
  }

  Future<void> setMode(TopikMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.activeTopikMode, mode.name);
  }

  Future<void> toggle() async {
    final next = state == TopikMode.topik1 ? TopikMode.topik2 : TopikMode.topik1;
    await setMode(next);
  }
}

final topikModeProvider = NotifierProvider<TopikModeNotifier, TopikMode>(() {
  return TopikModeNotifier();
});
