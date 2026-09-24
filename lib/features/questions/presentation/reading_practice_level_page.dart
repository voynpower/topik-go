import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';

/// TOPIK 급수 선택 후 [ReadingPracticePage]로 이동합니다.
class ReadingPracticeLevelPage extends StatelessWidget {
  const ReadingPracticeLevelPage({super.key});

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
          ..._levelData.map(
            (data) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => context.push('/reading-practice/${data.level}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: data.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${data.level}급',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: data.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    data.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F4F8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '30문항',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.desc,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelMeta {
  const _LevelMeta({
    required this.level,
    required this.title,
    required this.desc,
    required this.color,
  });

  final int level;
  final String title;
  final String desc;
  final Color color;
}

const _levelData = [
  _LevelMeta(
    level: 3,
    title: '3급 초중급 읽기',
    desc: '기본 안내문, 실용문 및 일상적 글 독해',
    color: Color(0xFF0F8C63),
  ),
  _LevelMeta(
    level: 4,
    title: '4급 중급 읽기',
    desc: '사회적 주제, 뉴스 기사, 일반 설명문 독해',
    color: Color(0xFF2E6BD9),
  ),
  _LevelMeta(
    level: 5,
    title: '5급 중고급 읽기',
    desc: '전문적 논설문, 경제/사회 이슈 및 칼럼 독해',
    color: Color(0xFF6E5BD8),
  ),
  _LevelMeta(
    level: 6,
    title: '6급 최고급 읽기',
    desc: '학술 연구, 심층 비평 및 고난도 문맥 추론',
    color: Color(0xFFD07A21),
  ),
];
