import 'package:flutter/material.dart';
import 'package:topik_go/app/theme/app_colors.dart';

class MockExamPage extends StatelessWidget {
  const MockExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모의고사')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('모의고사 풀기', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '실제 시험과 같은 환경에서 모의고사 풀기!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.mintDark),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('한국어능력시험 제 107회'),
                    SizedBox(height: 6),
                    Text(
                      'D-28',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('등록기간 04/01 ~ 04/10'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(onPressed: () {}, child: const Text('시작하기')),
          ],
        ),
      ),
    );
  }
}
