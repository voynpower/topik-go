import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/services/translation_service.dart';

import 'package:topik_go/features/questions/data/question_ai_explanation.dart';
import 'package:topik_go/features/questions/data/question_repository.dart';

class QuestionAiExplanationSheet extends ConsumerStatefulWidget {
  const QuestionAiExplanationSheet({
    super.key,
    required this.questionId,
    required this.selectedOption,
    this.correctAnswer,
    this.questionTitle,
  });

  final String questionId;
  final String selectedOption;
  final String? correctAnswer;
  final String? questionTitle;

  static Future<void> show(
    BuildContext context, {
    required String questionId,
    required String selectedOption,
    String? correctAnswer,
    String? questionTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuestionAiExplanationSheet(
        questionId: questionId,
        selectedOption: selectedOption,
        correctAnswer: correctAnswer,
        questionTitle: questionTitle,
      ),
    );
  }

  @override
  ConsumerState<QuestionAiExplanationSheet> createState() =>
      _QuestionAiExplanationSheetState();
}

class _QuestionAiExplanationSheetState
    extends ConsumerState<QuestionAiExplanationSheet> {
  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(currentLanguageProvider);
    final params = (
      questionId: widget.questionId,
      selectedOption: widget.selectedOption,
      languageCode: currentLang,
    );

    final aiAsync = ref.watch(questionAiExplanationProvider(params));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
            // Top handle & Header
            _buildHeader(context, currentLang),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Content body
            Flexible(
              child: aiAsync.when(
                loading: () => _buildLoadingState(currentLang),
                error: (error, _) => _buildErrorState(context, currentLang, params),
                data: (data) => _buildContent(context, data, currentLang),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    final headerTitle = _getHeaderTitle(lang);
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
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
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
                      headerTitle,
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
                          widget.questionTitle ?? '문제 해설',
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
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$flag ${_getLanguageName(lang)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F46E5),
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
    final loadingMsg = _getLoadingMessage(lang);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loadingMsg,
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
    QuestionAiExplanationParams params,
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
              ref.invalidate(questionAiExplanationProvider(params));
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(_getRetryLabel(lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
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
    QuestionAiExplanation data,
    String lang,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Answer comparison bar
          _buildComparisonBanner(data, lang),
          const SizedBox(height: 18),

          // 2. Wrong Answer Analysis (if incorrect)
          if (!data.isCorrect && data.wrongReason.isNotEmpty) ...[
            _buildSectionCard(
              title: _getWrongSectionTitle(lang, data.selectedOption),
              content: data.wrongReason,
              accentColor: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEF2F2),
              icon: Icons.cancel_outlined,
            ),
            const SizedBox(height: 14),
          ],

          // 3. Correct Answer Analysis
          if (data.correctReason.isNotEmpty) ...[
            _buildSectionCard(
              title: _getCorrectSectionTitle(lang, data.correctAnswer),
              content: data.correctReason,
              accentColor: const Color(0xFF10B981),
              bgColor: const Color(0xFFF0FDF4),
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 14),
          ],

          // 4. Key Vocabulary
          if (data.keyVocabulary.isNotEmpty) ...[
            _buildVocabularyCard(data.keyVocabulary, lang),
            const SizedBox(height: 14),
          ],

          // 5. Practical Exam Tip
          if (data.tip.isNotEmpty) ...[
            _buildSectionCard(
              title: _getTipSectionTitle(lang),
              content: data.tip,
              accentColor: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
              icon: Icons.lightbulb_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonBanner(QuestionAiExplanation data, String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: data.isCorrect
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    data.isCorrect ? Icons.check : Icons.close,
                    size: 16,
                    color: data.isCorrect
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMyChoiceLabel(lang),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${data.selectedOption}번 선택',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: data.isCorrect
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.done_all_rounded,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCorrectChoiceLabel(lang),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${data.correctAnswer}번 (정답)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              fontSize: 14,
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
                _getVocabSectionTitle(lang),
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
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
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

  // --- Multi-language label helpers ---
  String _getHeaderTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return '1:1 Moslashtirilgan AI Tushuntirish';
      case 'ru':
        return 'Индивидуальный разбор от ИИ';
      case 'en':
        return '1:1 Tailored AI Explanation';
      case 'vi':
        return 'Giải thích chi tiết 1:1 cùng AI';
      case 'ko':
      default:
        return '1:1 맞춤형 AI 오답 해설';
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

  String _getLoadingMessage(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return 'AI savol va siz tanlagan javobni tahlil qilmoqda...';
      case 'ru':
        return 'ИИ анализирует контекст вопроса и ваш ответ...';
      case 'en':
        return 'AI is analyzing the passage and your answer...';
      case 'vi':
        return 'AI đang phân tích ngữ cảnh câu hỏi và đáp án của bạn...';
      case 'ko':
      default:
        return 'AI가 지문과 학생이 고른 오답의 맥락을 정밀 분석 중입니다...';
    }
  }

  String _getLoadingSub(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "Nega bu javob xato ekanligi ona tilingizda tushuntiriladi.";
      case 'ru':
        return 'Причина ошибки будет объяснена на вашем родном языке.';
      case 'en':
        return 'The exact reason will be explained in your language.';
      case 'ko':
      default:
        return '모국어로 왜 오답이고 정답인지 알기 쉽게 짚어드립니다.';
    }
  }

  String _getErrorMessage(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return 'Tushuntirishni yuklab bo‘lmadi. Qaytadan urinib ko‘ring.';
      case 'ru':
        return 'Не удалось загрузить объяснение. Попробуйте еще раз.';
      case 'en':
        return 'Failed to load explanation. Please try again.';
      case 'ko':
      default:
        return '해설을 불러오지 못했습니다. 다시 시도해주세요.';
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

  String _getMyChoiceLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return 'Mening javobim';
      case 'ru':
        return 'Ваш ответ';
      case 'en':
        return 'My Choice';
      case 'ko':
      default:
        return '내 선택';
    }
  }

  String _getCorrectChoiceLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "To'g'ri javob";
      case 'ru':
        return 'Правильный ответ';
      case 'en':
        return 'Correct Answer';
      case 'ko':
      default:
        return '정답';
    }
  }

  String _getWrongSectionTitle(String lang, String selected) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "❌ Siz tanlagan $selected-variant nega xato?";
      case 'ru':
        return '❌ Почему вариант $selected неверен?';
      case 'en':
        return '❌ Why option $selected is incorrect:';
      case 'ko':
      default:
        return '❌ 선택하신 $selected번이 오답인 이유';
    }
  }

  String _getCorrectSectionTitle(String lang, String correct) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "✅ To'g'ri javob ($correct-variant) asoslari:";
      case 'ru':
        return '✅ Почему вариант $correct правильный:';
      case 'en':
        return '✅ Why option $correct is the right answer:';
      case 'ko':
      default:
        return '✅ 정답 ($correct번) 근거 및 해설';
    }
  }

  String _getVocabSectionTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "💡 Kalit so'zlar (Lug'at)";
      case 'ru':
        return '💡 Ключевые слова';
      case 'en':
        return '💡 Key Vocabulary';
      case 'ko':
      default:
        return '💡 핵심 단어 팁';
    }
  }

  String _getTipSectionTitle(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return '📌 TOPIK Imtihon Maslahati';
      case 'ru':
        return '📌 Совет для экзамена TOPIK';
      case 'en':
        return '📌 TOPIK Exam Tip';
      case 'ko':
      default:
        return '📌 실전 문제 풀이 팁';
    }
  }
}
