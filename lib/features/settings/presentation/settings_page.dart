import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/auth/application/auth_controller.dart';
import 'package:topik_go/features/auth/data/auth_repository.dart';
import 'package:topik_go/features/users/data/admin_user_repository.dart';
import 'package:topik_go/features/users/data/user_profile.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String languageLabel = '미설정';
  String targetLevelLabel = '미설정';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(PrefsKeys.preferredLanguageCode);
    final targetLevel = prefs.getInt(PrefsKeys.targetTopikLevel);

    if (!mounted) return;
    setState(() {
      languageLabel = getLanguageDisplayName(languageCode);
      targetLevelLabel = targetLevel == null ? '미설정' : '$targetLevel급';
    });
  }

  Future<void> _showLanguagePicker() async {
    final currentCode = ref.read(currentLanguageProvider);
    final strings = ref.read(appStringsProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.language_outlined, color: AppColors.mintDark),
                    const SizedBox(width: 8),
                    Text(
                      strings.chooseLanguage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: kSupportedLanguages.length,
                  itemBuilder: (ctx, index) {
                    final lang = kSupportedLanguages[index];
                    final isSelected = lang.code == currentCode;

                    return ListTile(
                      title: Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppColors.mintDark : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        lang.name,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.mintDark)
                          : null,
                      onTap: () async {
                        Navigator.of(bottomSheetContext).pop();
                        await ref.read(currentLanguageProvider.notifier).setLanguage(lang.code);
                        if (!mounted) return;
                        setState(() {
                          languageLabel = getLanguageDisplayName(lang.code);
                        });
                        final updatedStrings = ref.read(appStringsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(updatedStrings.languageChangedNotice),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAppInfoModal() async {
    final currentLang = ref.read(currentLanguageProvider);
    final isKorean = currentLang == 'ko';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 14,
            bottom: MediaQuery.of(bottomSheetContext).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.mint, AppColors.mintDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mintDark.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flutter_dash,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'TOPIK GO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mintDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'v1.0.0 (Build 1)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mintDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.mint.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    isKorean
                        ? 'TopikGo는 한국어능력시험(TOPIK II)을 준비하는 글로벌 학습자를 위한 맞춤형 학습 플랫폼입니다. 영역별 기출 연습, 실전 모의고사, OneVoca/OneGrammar 학습 시스템 및 다국어 지원을 제공합니다.'
                        : 'TopikGo is a smart TOPIK II learning mobile application for global Korean learners, offering practice sets, mock exams, OneVoca/OneGrammar study systems, and multilingual localization.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isKorean ? '주요 학습 기능 (Key Features)' : 'Key Features',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoFeatureRow(
                  icon: Icons.auto_stories_outlined,
                  title: isKorean ? '영역별 학습 & 기출 풀이' : 'Domain Practice (R/L/W)',
                  description: isKorean
                      ? '읽기, 듣기(오디오/TTS 플레이어 연동), 쓰기(단답/에세이) 실전 연습'
                      : 'Reading, Listening with interactive audio, and Writing essay practice',
                ),
                _buildInfoFeatureRow(
                  icon: Icons.timer_outlined,
                  title: isKorean ? '실전 모의고사 & OMR' : 'Real Mock Exam & OMR',
                  description: isKorean
                      ? '실제 시험 시간 타이머, 연속 듣기 재생목록 및 OMR 자동 채점'
                      : 'Real TOPIK exam timer, continuous listening playlist & automatic scoring',
                ),
                _buildInfoFeatureRow(
                  icon: Icons.translate_outlined,
                  title: isKorean ? 'OneVoca & OneGrammar' : 'OneVoca & OneGrammar',
                  description: isKorean
                      ? '플래시카드, 퀴즈, 받아쓰기, AI 예문 및 카테고리별 맞춤 문법 학습'
                      : 'Flashcards, quizzes, dictation, AI sentences & category grammar hub',
                ),
                _buildInfoFeatureRow(
                  icon: Icons.public_outlined,
                  title: isKorean ? '9개국 글로벌 다국어 지원' : '9-Language Localization',
                  description: isKorean
                      ? '한국어, English, O\'zbekcha, Tiếng Việt, Русский, 中文, 日本語 등'
                      : 'Korean, English, Uzbek, Vietnamese, Russian, Chinese, Japanese, and more',
                ),
                _buildInfoFeatureRow(
                  icon: Icons.cloud_sync_outlined,
                  title: isKorean ? '오프라인 캐싱 & 데이터 동기화' : 'Offline Storage & Sync',
                  description: isKorean
                      ? 'Drift/SQLite 로컬 데이터베이스 기반 오프라인 풀이 및 온라인 자동 동기화'
                      : 'Drift/SQLite local database storage with automatic server synchronization',
                ),
                const SizedBox(height: 14),
                Text(
                  isKorean ? '기술 스택 (Tech Stack)' : 'Tech Stack',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      _buildTechRow('Framework', 'Flutter 3.41 / Dart 3.11'),
                      const Divider(height: 14),
                      _buildTechRow('Architecture', 'Feature-First Clean Architecture'),
                      const Divider(height: 14),
                      _buildTechRow('State Management', 'Flutter Riverpod'),
                      const Divider(height: 14),
                      _buildTechRow('Local DB & Storage', 'Drift (SQLite) & Secure Storage'),
                      const Divider(height: 14),
                      _buildTechRow('API & Cloud CDN', 'NestJS Backend / AWS CloudFront'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    '© 2026 TopikGo Team. All rights reserved.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mintDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    isKorean ? '확인' : 'OK',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.mintDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
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

  Widget _buildTechRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(strings.settingsTitle),
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
              _SettingsHero(strings: strings),
              const SizedBox(height: 22),
              _SectionTitle(icon: Icons.tune_outlined, title: strings.generalSettings),
              const SizedBox(height: 10),
              ...profile.when(
                data: (user) => _profileSettings(user, strings),
                loading: () => [
                  _SettingTile(
                    icon: Icons.person_outline,
                    title: strings.username,
                    value: strings.loading,
                  ),
                  _SettingTile(
                    icon: Icons.language_outlined,
                    title: strings.languageSetting,
                    value: getLanguageDisplayName(ref.watch(currentLanguageProvider)),
                    onTap: _showLanguagePicker,
                  ),
                  _SettingTile(
                    icon: Icons.flag_outlined,
                    title: strings.targetLevel,
                    value: targetLevelLabel,
                  ),
                ],
                error: (_, _) => [
                  _SettingTile(
                    icon: Icons.person_outline,
                    title: strings.username,
                    value: strings.error,
                  ),
                  _SettingTile(
                    icon: Icons.language_outlined,
                    title: strings.languageSetting,
                    value: getLanguageDisplayName(ref.watch(currentLanguageProvider)),
                    onTap: _showLanguagePicker,
                  ),
                  _SettingTile(
                    icon: Icons.flag_outlined,
                    title: strings.targetLevel,
                    value: targetLevelLabel,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                icon: Icons.storage_outlined,
                title: strings.dataManagement,
              ),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.bookmark_remove_outlined,
                title: strings.clearBookmarks,
                value: strings.clearBookmarksDesc,
              ),
              _SettingTile(
                icon: Icons.info_outline,
                title: strings.appInfo,
                value: strings.appInfoDesc,
                onTap: _showAppInfoModal,
              ),
              const SizedBox(height: 18),
              _SectionTitle(icon: Icons.lock_outline, title: strings.accountSection),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.password_outlined,
                title: strings.changePassword,
                value: '',
                onTap: _changePassword,
              ),
              _SettingTile(
                icon: Icons.logout_outlined,
                title: strings.logout,
                value: '',
                onTap: () async {
                  await ref.read(authRepositoryProvider).logout();
                  ref.invalidate(userProfileProvider);
                  if (context.mounted) {
                    context.go('/auth/login');
                  }
                },
              ),
              ...profile.maybeWhen(
                data: (user) => user.isAdmin
                    ? [
                        const SizedBox(height: 18),
                        _SectionTitle(
                          icon: Icons.admin_panel_settings_outlined,
                          title: strings.adminMenu,
                        ),
                        const SizedBox(height: 10),
                        _SettingTile(
                          icon: Icons.search_outlined,
                          title: strings.manageUsers,
                          value: 'ID로 사용자 정보 확인',
                          onTap: _findAdminUser,
                        ),
                        _SettingTile(
                          icon: Icons.library_books_outlined,
                          title: strings.manageQuestionSets,
                          value: '생성, 수정, 삭제',
                          onTap: () => context.push('/admin/question-sets'),
                        ),
                      ]
                    : const [],
                orElse: () => const [],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _profileSettings(UserProfile profile, AppStrings strings) {
    return [
      _SettingTile(
        icon: Icons.person_outline,
        title: strings.username,
        value: profile.nickname,
      ),
      _SettingTile(
        icon: Icons.mail_outline,
        title: strings.email,
        value: profile.email ?? '미등록',
      ),
      _SettingTile(
        icon: Icons.verified_user_outlined,
        title: strings.role,
        value: profile.role,
      ),
      _SettingTile(
        icon: Icons.language_outlined,
        title: strings.languageSetting,
        value: getLanguageDisplayName(ref.watch(currentLanguageProvider)),
        onTap: _showLanguagePicker,
      ),
      _SettingTile(
        icon: Icons.flag_outlined,
        title: strings.targetLevel,
        value: '${profile.targetLevel}급',
      ),
      _SettingTile(
        icon: Icons.format_size_outlined,
        title: strings.fontSize,
        value: '${profile.fontScale}x',
      ),
      _SettingTile(
        icon: Icons.schedule_outlined,
        title: strings.timezone,
        value: profile.timezone,
      ),
    ];
  }

  Future<void> _findAdminUser() async {
    final id = await _askUserId(title: '사용자 조회');
    if (id == null) return;

    try {
      final user = await ref.read(adminUserRepositoryProvider).getUser(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('사용자 정보'),
          content: Text(
            [
              'ID: ${user.id}',
              'Email: ${user.email ?? '미등록'}',
              'Nickname: ${user.nickname}',
              'Role: ${user.role}',
              'Level: ${user.targetLevel}',
              'Language: ${user.languageCode}',
            ].join('\n'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<String?> _askUserId({required String title}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '사용자 ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final id = controller.text.trim();
              if (id.isEmpty) return;
              Navigator.of(context).pop(id);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _changePassword() async {
    final strings = ref.read(appStringsProvider);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.changePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '현재 비밀번호'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '새 비밀번호'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '새 비밀번호 확인'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                final current = currentController.text;
                final next = newController.text;
                final confirm = confirmController.text;

                if (current.isEmpty || next.isEmpty || next != confirm) {
                  return;
                }

                Navigator.of(context).pop((current: current, next: next));
              },
              child: Text(strings.confirm),
            ),
          ],
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (result == null) return;

    final success = await ref
        .read(authControllerProvider)
        .changePassword(
          currentPassword: result.current,
          newPassword: result.next,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '비밀번호가 변경되었습니다.' : '비밀번호 변경에 실패했습니다.')),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.strings});

  final AppStrings strings;

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
              Icons.settings_outlined,
              color: AppColors.mintDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.appSettingsHeroTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  strings.appSettingsHeroDesc,
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

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.mintDark, size: 25),
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
                      if (value.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
