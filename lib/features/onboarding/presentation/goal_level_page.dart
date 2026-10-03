import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';

class GoalLevelPage extends StatefulWidget {
  const GoalLevelPage({super.key});

  @override
  State<GoalLevelPage> createState() => _GoalLevelPageState();
}

class _GoalLevelPageState extends State<GoalLevelPage> {
  int selectedLevel = 1;

  final descriptions = const {
    1: 'TOPIK I (1급) / 자기소개, 식당 주문 등 기초 일상 표현',
    2: 'TOPIK I (2급) / 전화, 부탁 등 일상생활 및 우체국·은행 이용',
    3: 'TOPIK II (3급) / 일상 대화 및 대중시설 이용에 불편함이 없는 수준',
    4: 'TOPIK II (4급) / 뉴스, 신문 기사 등 일반적인 사회적 주제 이해',
    5: 'TOPIK II (5급) / 전문 분야 연구 및 업무 수행에 필요한 언어 구사',
    6: 'TOPIK II (6급) / 원어민 수준의 유창하고 정확한 의사소통',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLevel();
  }

  Future<void> _loadSavedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt(PrefsKeys.targetTopikLevel);

    if (!mounted || savedLevel == null || savedLevel < 1 || savedLevel > 6) {
      return;
    }

    setState(() => selectedLevel = savedLevel);
  }

  Future<void> _saveGoalAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.targetTopikLevel, selectedLevel);
    await prefs.setString(
      PrefsKeys.activeTopikMode,
      selectedLevel <= 2 ? 'topik1' : 'topik2',
    );
    await prefs.setBool(PrefsKeys.onboardingCompleted, true);

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('목표 등급을 선택하세요', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            ...[1, 2, 3, 4, 5, 6].map((level) {
              final active = selectedLevel == level;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: active ? AppColors.mint : AppColors.border,
                    ),
                  ),
                  title: Text(
                    '$level급',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(descriptions[level] ?? ''),
                  ),
                  trailing: Icon(
                    active ? Icons.check_circle : Icons.circle_outlined,
                    color: active
                        ? AppColors.mintDark
                        : AppColors.textSecondary,
                  ),
                  onTap: () => setState(() => selectedLevel = level),
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saveGoalAndContinue,
              child: const Text('Next Step'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
