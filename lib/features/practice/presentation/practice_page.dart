import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/questions/data/listening_practice_set.dart';
import 'package:topik_go/features/questions/data/reading_practice_set.dart';
import 'package:topik_go/features/questions/data/writing_practice_set.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('학습'),
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F8F6), Color(0xFFF8FBFF), Color(0xFFFFF8EA)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _PracticeHero(),
              const SizedBox(height: 22),
              const _SectionTitle(
                icon: Icons.quiz_outlined,
                title: '유형별 문제 풀기',
              ),
              const SizedBox(height: 10),
              _MenuTile(
                icon: Icons.menu_book_outlined,
                iconColor: const Color(0xFF1D8F86),
                backgroundColor: const Color(0xFFE8F8F3),
                title: '읽기 문제',
                subtitle: '급수 선택 후 연습 · 최대 ${ReadingPracticeSet.total}문항',
                onTap: () => context.push('/reading-practice'),
              ),
              _MenuTile(
                icon: Icons.headphones_outlined,
                iconColor: const Color(0xFF2E6BD9),
                backgroundColor: const Color(0xFFEAF1FF),
                title: '듣기 문제',
                subtitle: '급수 선택 후 연습 · 최대 ${ListeningPracticeSet.total}문항',
                onTap: () => context.push('/listening-practice'),
              ),
              _MenuTile(
                icon: Icons.edit_note_outlined,
                iconColor: const Color(0xFFD07A21),
                backgroundColor: const Color(0xFFFFF1DC),
                title: '쓰기 문제',
                subtitle:
                    '${WritingPracticeSet.level}급 / ${WritingPracticeSet.total}문항',
                onTap: () => context.push('/writing-practice'),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                icon: Icons.auto_stories_outlined,
                title: '학습 도구',
              ),
              const SizedBox(height: 10),
              _MenuTile(
                icon: Icons.play_circle_outline,
                iconColor: const Color(0xFFE05268),
                backgroundColor: const Color(0xFFFFEEF1),
                title: '문제 해설 영상',
                subtitle: '문제 해설 영상을 열람해보세요',
                onTap: () => context.push('/explanation-videos'),
              ),
              _MenuTile(
                icon: Icons.translate_outlined,
                iconColor: const Color(0xFF0F8C63),
                backgroundColor: const Color(0xFFE9F7EF),
                title: '단어장',
                subtitle: 'TOPIK 단어를 검색하고 저장하세요',
                onTap: () => context.push('/vocabulary'),
              ),
              _MenuTile(
                icon: Icons.psychology_alt_outlined,
                iconColor: const Color(0xFF6E5BD8),
                backgroundColor: const Color(0xFFF0EEFF),
                title: '문법 공부',
                subtitle: '문법 패턴을 검색하고 예문을 확인하세요',
                onTap: () => context.push('/grammar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeHero extends StatelessWidget {
  const _PracticeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDark.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.mintDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOPIK II 학습',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '읽기, 듣기, 쓰기와 핵심 학습 도구를 한 곳에서 시작하세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mintDark),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
