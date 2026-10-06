import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/questions/data/question_ai_explanation.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';

class WritingAiFeedbackSheet extends ConsumerStatefulWidget {
  const WritingAiFeedbackSheet({
    super.key,
    required this.questionId,
    required this.userAnswer,
    this.questionTitle,
  });

  final String questionId;
  final String userAnswer;
  final String? questionTitle;

  static Future<void> show(
    BuildContext context, {
    required String questionId,
    required String userAnswer,
    String? questionTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WritingAiFeedbackSheet(
        questionId: questionId,
        userAnswer: userAnswer,
        questionTitle: questionTitle,
      ),
    );
  }

  @override
  ConsumerState<WritingAiFeedbackSheet> createState() =>
      _WritingAiFeedbackSheetState();
}

class _WritingAiFeedbackSheetState
    extends ConsumerState<WritingAiFeedbackSheet> {
  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(currentLanguageProvider);
    final params = (
      questionId: widget.questionId,
      userAnswer: widget.userAnswer,
      languageCode: currentLang,
    );

    final aiAsync = ref.watch(questionAiWritingFeedbackProvider(params));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, currentLang),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Flexible(
              child: aiAsync.when(
                loading: () => _buildLoadingState(currentLang),
                error: (error, _) =>
                    _buildErrorState(context, currentLang, params),
                data: (data) => _buildContent(context, data, currentLang),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    final flag = _getLanguageFlag(lang);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getHeaderTitle(lang),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          widget.questionTitle ?? '쓰기 첨삭',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$flag ${_getLanguageName(lang)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getLoadingMessage(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getLoadingSub(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String lang,
    QuestionAiWritingFeedbackParams params,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          Text(
            _getErrorMessage(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(questionAiWritingFeedbackProvider(params));
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(_getRetryLabel(lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    QuestionAiWritingFeedback data,
    String lang,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Estimated Score Banner
          if (data.scoreEstimate.isNotEmpty) ...[
            _buildScoreBanner(data.scoreEstimate, lang),
            const SizedBox(height: 16),
          ],

          // 2. Grammar & Spelling Corrections
          _buildCorrectionsCard(data.grammarCorrections, lang),
          const SizedBox(height: 14),

          // 3. Deduction Points (감점 요인)
          if (data.deductionPoints.isNotEmpty) ...[
            _buildSectionCard(
              title: _getDeductionTitle(lang),
              content: data.deductionPoints,
              accentColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 14),
          ],

          // 4. Polished Version (AI 모범 교정문)
          if (data.polishedVersion.isNotEmpty) ...[
            _buildPolishedCard(context, data.polishedVersion, lang),
            const SizedBox(height: 14),
          ],

          // 5. Native Feedback (종합 총평)
          if (data.nativeFeedback.isNotEmpty) ...[
            _buildSectionCard(
              title: _getFeedbackTitle(lang),
              content: data.nativeFeedback,
              accentColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              icon: Icons.tips_and_updates_outlined,
            ),
            const SizedBox(height: 14),
          ],

          // 6. Key Vocabulary
          if (data.keyVocabulary.isNotEmpty) ...[
            _buildVocabularyCard(data.keyVocabulary, lang),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBanner(String score, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getScoreLabel(lang),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4338CA),
                  ),
                ),
                Text(
                  score,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionsCard(
    List<WritingGrammarCorrectionItem> corrections,
    String lang,
  ) {
    final hasCorrections = corrections.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCorrections ? Icons.spellcheck_rounded : Icons.check_circle_outline,
                size: 18,
                color: hasCorrections
                    ? const Color(0xFFD97706)
                    : const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Text(
                _getCorrectionsTitle(lang),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: hasCorrections
                      ? const Color(0xFFB45309)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasCorrections) ...[
            Text(
              _getNoCorrectionsMsg(lang),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
          ] else ...[
            for (int i = 0; i < corrections.length; i++) ...[
              if (i > 0) const Divider(height: 16, color: Color(0xFFE2E8F0)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13.5),
                            children: [
                              TextSpan(
                                text: corrections[i].original,
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(
                                text: '  ➔  ',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: corrections[i].corrected,
                                style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (corrections[i].reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      corrections[i].reason,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPolishedCard(
    BuildContext context,
    String polished,
    String lang,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    size: 18,
                    color: Color(0xFF15803D),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getPolishedTitle(lang),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: polished));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모범 문장이 클립보드에 복사되었습니다.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                color: const Color(0xFF15803D),
                tooltip: '복사하기',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            polished,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14532D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required Color accentColor,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(List<KeyVocabularyItem> vocabList, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              Text(
                _getVocabTitle(lang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vocabList.map((vocab) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    children: [
                      TextSpan(
                        text: vocab.korean,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const TextSpan(text: ' : '),
                      TextSpan(
                        text: vocab.translation,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Multi-language helper strings ---
  String _getHeaderTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "1:1 AI Yozish Tahriri (Insho)";
      case 'ru':
        return '1:1 ИИ-проверка письменной части';
      case 'en':
        return '1:1 Tailored AI Writing Feedback';
      case 'vi':
        return 'Chấm bài viết 1:1 cùng AI';
      case 'ko':
      default:
        return '1:1 맞춤형 AI 쓰기 첨삭';
    }
  }

  String _getLanguageName(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "O'zbek";
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      case 'ko':
      default:
        return '한국어';
    }
  }

  String _getLanguageFlag(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return '🇺🇿';
      case 'ru':
        return '🇷🇺';
      case 'en':
        return '🇬🇧';
      case 'vi':
        return '🇻🇳';
      case 'ko':
      default:
        return '🇰🇷';
    }
  }

  String _getScoreLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return 'Kutilayotgan ball (Taxminiy)';
      case 'ru':
        return 'Ориентировочный балл';
      case 'en':
        return 'Estimated Score';
      case 'ko':
      default:
        return '예상 획득 점수';
    }
  }

  String _getCorrectionsTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "Imlo va grammatika tuzatishlari";
      case 'ru':
        return 'Исправление орфографии и грамматики';
      case 'en':
        return 'Grammar & Spelling Corrections';
      case 'ko':
      default:
        return '맞춤법 및 문법 교정';
    }
  }

  String _getNoCorrectionsMsg(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "Ajoyib! Hech qanday imlo yoki grammatik xato topilmadi.";
      case 'ru':
        return 'Отлично! Ошибок в правописании и грамматике не обнаружено.';
      case 'en':
        return 'Great job! No spelling or grammatical errors found.';
      case 'ko':
      default:
        return '축하합니다! 눈에 띄는 문법 및 맞춤법 오류가 없습니다.';
    }
  }

  String _getDeductionTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "⚠️ Ball tushish sabablari (Kamchiliklar)";
      case 'ru':
        return '⚠️ Причины снижения баллов';
      case 'en':
        return '⚠️ Score Deduction Points';
      case 'ko':
      default:
        return '⚠️ 주요 감점 요인 분석';
    }
  }

  String _getPolishedTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "✨ Mukammallashtirilgan Namunaviy Matn";
      case 'ru':
        return '✨ Улучшенная версия (Образец)';
      case 'en':
        return '✨ Polished Model Version';
      case 'ko':
      default:
        return '✨ AI 추천 모범 교정문 (고급 표현)';
    }
  }

  String _getFeedbackTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "💡 Umumiy xulosa va maslahatlar";
      case 'ru':
        return '💡 Общий отзыв и рекомендации';
      case 'en':
        return '💡 Overall Feedback & Exam Advice';
      case 'ko':
      default:
        return '💡 총평 및 실전 고득점 조언';
    }
  }

  String _getVocabTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "📚 Yuqori ball beruvchi kalit so'zlar";
      case 'ru':
        return '📚 Ключевая лексика для высокого балла';
      case 'en':
        return '📚 High-Scoring Key Vocabulary';
      case 'ko':
      default:
        return '📚 추천 고급 표현 및 어휘';
    }
  }

  String _getLoadingMessage(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "AI yozma javobingizni qoidalar asosida tekshirmoqda...";
      case 'ru':
        return 'ИИ анализирует и проверяет ваш письменный ответ...';
      case 'en':
        return 'AI is grading and polishing your writing answer...';
      case 'ko':
      default:
        return 'AI 채점관이 작성하신 쓰기 답안을 정밀 첨삭 중입니다...';
    }
  }

  String _getLoadingSub(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "Grammatika, imlo va uslubiy xatolar ona tilingizda tahlil qilinadi.";
      case 'ru':
        return 'Ошибки и рекомендации будут объяснены на вашем языке.';
      case 'en':
        return 'Grammar, spelling, and style deductions will be explained.';
      case 'ko':
      default:
        return '맞춤법 교정과 감점 요인을 모국어로 알기 쉽게 짚어드립니다.';
    }
  }

  String _getErrorMessage(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "Tahrir natijasini yuklab bo'lmadi. Qaytadan urinib ko'ring.";
      case 'ru':
        return 'Не удалось загрузить результат проверки. Попробуйте снова.';
      case 'en':
        return 'Failed to load writing feedback. Please try again.';
      case 'ko':
      default:
        return '첨삭 결과를 불러오지 못했습니다. 다시 시도해주세요.';
    }
  }

  String _getRetryLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return 'Qayta urinish';
      case 'ru':
        return 'Повторить';
      case 'en':
        return 'Retry';
      case 'ko':
      default:
        return '다시 시도';
    }
  }
}
