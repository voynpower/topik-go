import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/question_sets/data/question_set.dart';
import 'package:topik_go/features/questions/presentation/widgets/writing_ai_feedback_sheet.dart';

class WritingAiFeedbackButton extends ConsumerWidget {
  const WritingAiFeedbackButton({
    super.key,
    required this.question,
    required this.userAnswer,
    this.isFullWidth = true,
  });

  final Question question;
  final String userAnswer;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userAnswer.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final currentLang = ref.watch(currentLanguageProvider);
    final label = _getButtonLabel(currentLang);

    final buttonWidget = InkWell(
      onTap: () {
        WritingAiFeedbackSheet.show(
          context,
          questionId: question.id,
          userAnswer: userAnswer.trim(),
          questionTitle: '${question.section} ${question.questionNumber}번',
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF2563EB),
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
        return "✍️ AI 1:1 Insho Tahriri va Maslahat (O'zbekcha)";
      case 'ru':
        return '✍️ AI 1:1 Проверка и разбор сочинения (Русский)';
      case 'en':
        return '✍️ 1:1 AI Writing Correction & Feedback';
      case 'vi':
        return '✍️ Chấm bài viết 1:1 cùng AI (Tiếng Việt)';
      case 'ko':
      default:
        return '✍️ AI 1:1 맞춤 쓰기 첨삭 및 감점 분석';
    }
  }
}
