import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _SectionTitle('일반 설정'),
          _SettingTile(title: '언어 설정', value: '한국어'),
          _SettingTile(title: '글자 크기', value: '1.00x'),
          _SettingTile(title: '타임존', value: '+09:00'),
          SizedBox(height: 16),
          _SectionTitle('데이터 관리'),
          _SettingTile(title: '북마크 초기화', value: '저장된 모든 북마크 삭제'),
          _SettingTile(title: '앱 정보', value: '버전 정보 및 각종 정책 안내'),
          SizedBox(height: 16),
          _SectionTitle('계정'),
          _SettingTile(title: '비밀번호 재설정', value: ''),
          _SettingTile(title: '로그아웃', value: ''),
          _SettingTile(title: '회원 탈퇴', value: ''),
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
