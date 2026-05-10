import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
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
      languageLabel = _languageFromCode(languageCode);
      targetLevelLabel = targetLevel == null ? '미설정' : '$targetLevel급';
    });
  }

  String _languageFromCode(String? code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'uz':
        return "O'zbekcha";
      case 'vi':
        return 'Tiếng Việt';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return '미설정';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('일반 설정'),
          ...profile.when(
            data: _profileSettings,
            loading: () => [
              const _SettingTile(title: '프로필', value: '불러오는 중...'),
              _SettingTile(title: '언어 설정', value: languageLabel),
              _SettingTile(title: '목표 등급', value: targetLevelLabel),
            ],
            error: (_, _) => [
              const _SettingTile(title: '프로필', value: '서버 프로필을 불러오지 못했습니다'),
              _SettingTile(title: '언어 설정', value: languageLabel),
              _SettingTile(title: '목표 등급', value: targetLevelLabel),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('데이터 관리'),
          const _SettingTile(title: '북마크 초기화', value: '저장된 모든 북마크 삭제'),
          const _SettingTile(title: '앱 정보', value: '버전 정보 및 각종 정책 안내'),
          const SizedBox(height: 16),
          const _SectionTitle('계정'),
          _SettingTile(title: '비밀번호 재설정', value: '', onTap: _changePassword),
          _SettingTile(
            title: '로그아웃',
            value: '',
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.go('/auth/login');
              }
            },
          ),
          const _SettingTile(title: '회원 탈퇴', value: ''),
          ...profile.maybeWhen(
            data: (user) => user.isAdmin
                ? [
                    const SizedBox(height: 16),
                    const _SectionTitle('관리자'),
                    _SettingTile(
                      title: '사용자 조회',
                      value: 'ID로 사용자 정보 확인',
                      onTap: _findAdminUser,
                    ),
                    _SettingTile(
                      title: '사용자 수정',
                      value: 'ID로 사용자 설정 변경',
                      onTap: _updateAdminUser,
                    ),
                    _SettingTile(
                      title: '사용자 삭제',
                      value: 'ID로 사용자 계정 삭제',
                      onTap: _deleteAdminUser,
                    ),
                    _SettingTile(
                      title: '문제 세트 관리',
                      value: '생성, 수정, 삭제',
                      onTap: () => context.push('/admin/question-sets'),
                    ),
                  ]
                : const [],
            orElse: () => const [],
          ),
        ],
      ),
    );
  }

  List<Widget> _profileSettings(UserProfile profile) {
    return [
      _SettingTile(title: '사용자명', value: profile.nickname),
      _SettingTile(title: '이메일', value: profile.email ?? '미등록'),
      _SettingTile(title: '역할', value: profile.role),
      _SettingTile(
        title: '언어 설정',
        value: _languageFromCode(profile.languageCode),
      ),
      _SettingTile(title: '목표 등급', value: '${profile.targetLevel}급'),
      _SettingTile(title: '글자 크기', value: '${profile.fontScale}x'),
      _SettingTile(title: '타임존', value: profile.timezone),
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

  Future<void> _updateAdminUser() async {
    final id = await _askUserId(title: '사용자 수정');
    if (id == null) return;

    try {
      final user = await ref.read(adminUserRepositoryProvider).getUser(id);
      if (!mounted) return;
      final nicknameController = TextEditingController(text: user.nickname);
      final levelController = TextEditingController(
        text: user.targetLevel.toString(),
      );
      final languageController = TextEditingController(text: user.languageCode);

      final result =
          await showDialog<
            ({String nickname, int targetLevel, String language})
          >(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('사용자 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nicknameController,
                    decoration: const InputDecoration(labelText: '사용자명'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: levelController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '목표 등급'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: languageController,
                    decoration: const InputDecoration(labelText: '언어 코드'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final nickname = nicknameController.text.trim();
                    final level = int.tryParse(levelController.text.trim());
                    final language = languageController.text.trim();
                    if (nickname.isEmpty || level == null || language.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop((
                      nickname: nickname,
                      targetLevel: level,
                      language: language,
                    ));
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          );

      nicknameController.dispose();
      levelController.dispose();
      languageController.dispose();
      if (result == null) return;

      await ref.read(adminUserRepositoryProvider).updateUser(id, {
        'nickname': result.nickname,
        'target_level': result.targetLevel,
        'language_code': result.language,
      });
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자가 수정되었습니다.')));
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteAdminUser() async {
    final id = await _askUserId(title: '사용자 삭제');
    if (id == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 삭제'),
        content: Text('$id 사용자를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(adminUserRepositoryProvider).deleteUser(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자가 삭제되었습니다.')));
      }
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
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 재설정'),
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
              child: const Text('취소'),
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
              child: const Text('변경'),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, required this.value, this.onTap});

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: value.isEmpty ? null : Text(value),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
