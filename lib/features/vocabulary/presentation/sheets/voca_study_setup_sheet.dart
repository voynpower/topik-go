import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_mastery_service.dart';
import 'package:topik_go/features/vocabulary/domain/vocabulary_study_models.dart';

class VocaStudySetupSheet extends ConsumerStatefulWidget {
  const VocaStudySetupSheet({
    super.key,
    required this.mode,
  });

  final VocabularyStudyMode mode;

  static void show(BuildContext context, VocabularyStudyMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VocaStudySetupSheet(mode: mode),
    );
  }

  @override
  ConsumerState<VocaStudySetupSheet> createState() => _VocaStudySetupSheetState();
}

class _VocaStudySetupSheetState extends ConsumerState<VocaStudySetupSheet> {
  StudyWordSourceType _sourceType = StudyWordSourceType.all;
  WordMasteryStatus? _statusFilter;
  bool _isWordToMeaning = true;
  int _questionCount = 20;

  String _getModeTitle(AppStrings strings) {
    switch (widget.mode) {
      case VocabularyStudyMode.flashcard:
        return strings.flashcard;
      case VocabularyStudyMode.quiz:
        return strings.quiz;
      case VocabularyStudyMode.dictation:
        return strings.dictation;
      case VocabularyStudyMode.autoplay:
        return strings.autoplay;
    }
  }

  String get _routePath {
    switch (widget.mode) {
      case VocabularyStudyMode.flashcard:
        return '/vocabulary/flashcard';
      case VocabularyStudyMode.quiz:
        return '/vocabulary/quiz';
      case VocabularyStudyMode.dictation:
        return '/vocabulary/dictation';
      case VocabularyStudyMode.autoplay:
        return '/vocabulary/autoplay';
    }
  }

  void _onStart() {
    Navigator.of(context).pop();
    final queryParams = <String, String>{
      'source': _sourceType == StudyWordSourceType.saved ? 'saved' : 'all',
      'count': '$_questionCount',
      'direction': _isWordToMeaning ? 'word_to_meaning' : 'meaning_to_word',
    };
    if (_statusFilter != null) {
      queryParams['status'] = _statusFilter!.name;
    }

    context.push(Uri(path: _routePath, queryParameters: queryParams).toString());
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Text(
                _getModeTitle(strings),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. 단어 그룹 선택
          _SettingGroupContainer(
            children: [
              _SettingTile(
                title: strings.studySourceSheetTitle,
                value: _sourceType == StudyWordSourceType.saved ? strings.mySavedWordbook : strings.allTopikVocab,
                onTap: () {
                  setState(() {
                    _sourceType = _sourceType == StudyWordSourceType.saved
                        ? StudyWordSourceType.all
                        : StudyWordSourceType.saved;
                  });
                },
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // 2. 단어 암기 상태 필터
              _SettingTile(
                title: strings.selectWordLevel,
                value: _statusFilter == null
                    ? strings.all
                    : _statusFilter == WordMasteryStatus.hard
                        ? '🔴 ${strings.statusHard}'
                        : _statusFilter == WordMasteryStatus.unsure
                            ? '🟡 ${strings.statusUnsure}'
                            : '🟢 ${strings.statusMastered}',
                onTap: () {
                  setState(() {
                    if (_statusFilter == null) {
                      _statusFilter = WordMasteryStatus.hard;
                    } else if (_statusFilter == WordMasteryStatus.hard) {
                      _statusFilter = WordMasteryStatus.unsure;
                    } else if (_statusFilter == WordMasteryStatus.unsure) {
                      _statusFilter = WordMasteryStatus.mastered;
                    } else {
                      _statusFilter = null;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. 퀴즈/학습 방식 (단어->뜻 / 뜻->단어)
          _SettingGroupContainer(
            children: [
              _SettingTile(
                title: strings.quizDirection,
                value: _isWordToMeaning ? strings.wordToMeaning : strings.meaningToWord,
                onTap: () {
                  setState(() => _isWordToMeaning = !_isWordToMeaning);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. 구간별 문제 수 (10개 / 20개 / 40개)
          _SettingGroupContainer(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.questionsPerSet,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '$_questionCount개',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mintDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.questionsPerSetDesc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [10, 20, 40].map((cnt) {
                        final isSel = _questionCount == cnt;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setState(() => _questionCount = cnt),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.mintDark : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$cnt개',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mint,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _onStart,
              child: Text(
                strings.startStudyAction,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingGroupContainer extends StatelessWidget {
  const _SettingGroupContainer({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mintDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
