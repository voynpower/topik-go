import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';

class AiNoticePage extends StatelessWidget {
  const AiNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('AI 생성 콘텐츠 알림', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 48),
            Icon(
              Icons.auto_awesome_rounded,
              size: 86,
              color: AppColors.mintDark,
            ),
            const SizedBox(height: 28),
            Text(
              'LoroTOPIK에는 AI 생성 콘텐츠가 일부 포함되어 있으며,\n전문가와 편집자들의 검수를 거쳐 제공됩니다.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/language'),
              child: const Text('Start LoroTOPIK'),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
