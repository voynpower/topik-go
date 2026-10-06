import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/presentation/widgets/question_ai_explanation_sheet.dart';

class QuestionAiExplanationButton extends ConsumerWidget {
  const QuestionAiExplanationButton({
    super.key,
    required this.question,
    required this.selectedAnswer,
    this.isFullWidth = true,
  });

  final Question question;
  final String? selectedAnswer;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAnswer == null || selectedAnswer!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final currentLang = ref.watch(currentLanguageProvider);
    final label = _getButtonLabel(currentLang);

    final buttonWidget = InkWell(
      onTap: () {
        QuestionAiExplanationSheet.show(
          context,
          questionId: question.id,
          selectedOption: selectedAnswer!.trim(),
          correctAnswer: question.correctAnswer?.trim(),
          questionTitle: '${question.section} ${question.questionNumber}번',
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6D28D9),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonWidget,
      );
    }
    return buttonWidget;
  }

  String _getButtonLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return "🤖 AI 1:1 xato tahlili (O'zbekcha)";
      case 'ru':
        return '🤖 AI Разбор ошибок (Русский)';
      case 'en':
        return '🤖 1:1 AI Mistake Explainer';
      case 'vi':
        return '🤖 AI Giải thích lỗi sai (Tiếng Việt)';
      case 'ko':
      default:
        return '🤖 AI 1:1 맞춤 오답 해설';
    }
  }
}
