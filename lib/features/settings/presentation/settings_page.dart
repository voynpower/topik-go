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
