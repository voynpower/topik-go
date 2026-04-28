import 'package:flutter/material.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학습')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _MenuTile(title: '읽기 문제', subtitle: '다양한 유형의 읽기 문제를 연습'),
          _MenuTile(title: '듣기 문제', subtitle: '다양한 유형의 듣기 문제를 연습'),
          _MenuTile(title: '쓰기 문제', subtitle: '다양한 유형의 쓰기 문제를 연습'),
          SizedBox(height: 16),
          _MenuTile(title: '문제 해설 영상', subtitle: '문제 해설 영상을 열람해보세요'),
          _MenuTile(title: '단어장', subtitle: 'TOPIK 단어를 학습하고 TTS로 발음 연습'),
          _MenuTile(title: '문법 공부', subtitle: '다양한 문법을 배워보세요'),
          _MenuTile(title: '오프라인 저장 데이터', subtitle: '오프라인 저장 데이터 열람'),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
