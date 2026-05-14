import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';

/// TOPIK 급수 선택 후 [ReadingPracticePage]로 이동합니다.
class ReadingPracticeLevelPage extends StatelessWidget {
  const ReadingPracticeLevelPage({super.key});

  static const _levels = [3, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(title: const Text('읽기 연습')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'TOPIK II 급수 선택',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '선택한 급수에 맞는 읽기 문제 세트와 문항을 불러옵니다.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ..._levels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  title: Text(
                    '$level급',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('TOPIK II'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reading-practice/$level'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
