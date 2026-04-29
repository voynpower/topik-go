import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('일반 설정'),
          _SettingTile(title: '언어 설정', value: languageLabel),
          _SettingTile(title: '목표 등급', value: targetLevelLabel),
          const _SettingTile(title: '글자 크기', value: '1.00x'),
          const _SettingTile(title: '타임존', value: '+09:00'),
          const SizedBox(height: 16),
          const _SectionTitle('데이터 관리'),
          const _SettingTile(title: '북마크 초기화', value: '저장된 모든 북마크 삭제'),
          const _SettingTile(title: '앱 정보', value: '버전 정보 및 각종 정책 안내'),
          const SizedBox(height: 16),
          const _SectionTitle('계정'),
          const _SettingTile(title: '비밀번호 재설정', value: ''),
          const _SettingTile(title: '로그아웃', value: ''),
          const _SettingTile(title: '회원 탈퇴', value: ''),
        ],
      ),
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
  const _SettingTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: value.isEmpty ? null : Text(value),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
