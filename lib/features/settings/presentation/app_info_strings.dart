import 'package:flutter/material.dart';

class AppInfoFeatureItem {
  const AppInfoFeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class AppInfoData {
  const AppInfoData({
    required this.locale,
    required this.version,
    required this.description,
    required this.featuresTitle,
    required this.features,
    required this.techTitle,
    required this.techInfo,
    required this.confirmButton,
    required this.copyright,
  });

  final String locale;
  final String version;
  final String description;
  final String featuresTitle;
  final List<AppInfoFeatureItem> features;
  final String techTitle;
  final String techInfo;
  final String confirmButton;
  final String copyright;

  static AppInfoData of(String? languageCode) {
    switch (languageCode) {
      case 'en':
        return _en;
      case 'uz':
        return _uz;
      case 'ru':
        return _ru;
      case 'vi':
        return _vi;
      case 'zh':
        return _zh;
      case 'ja':
        return _ja;
      case 'fr':
        return _fr;
      case 'de':
        return _de;
      case 'ko':
      default:
        return _ko;
    }
  }

  // -------------------------------------------------------------
  // Korean (한국어)
  // -------------------------------------------------------------
  static const AppInfoData _ko = AppInfoData(
    locale: 'ko',
    version: 'v1.0.0 (최신 버전)',
    description: 'TOPIK GO는 한국어능력시험(TOPIK I & TOPIK II) 목표 등급 달성을 위한 글로벌 학습 플랫폼입니다.',
    featuresTitle: '주요 기능',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: '영역별 기출 풀이',
        description: '읽기 · 듣기 · 쓰기',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: '실전 모의고사',
        description: '시험 타이머 & OMR 채점',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: '스마트 어휘·문법',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: '모국어 맞춤 지원',
        description: '9개 언어 해설 & 오프라인',
      ),
    ],
    techTitle: '기술 스택',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: '확인',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // English (영어)
  // -------------------------------------------------------------
  static const AppInfoData _en = AppInfoData(
    locale: 'en',
    version: 'v1.0.0 (Latest Version)',
    description: 'TOPIK GO is a global learning platform designed to help you achieve your target TOPIK I & TOPIK II level.',
    featuresTitle: 'Key Features',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: 'Domain Practice',
        description: 'Reading · Listening · Writing',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: 'Real Mock Exam',
        description: 'Exam Timer & OMR Scoring',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: 'Smart Voca & Grammar',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: 'Native Language Support',
        description: '9 Languages & Offline Study',
      ),
    ],
    techTitle: 'Tech Stack',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: 'OK',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // Uzbek (우즈베크어)
  // -------------------------------------------------------------
  static const AppInfoData _uz = AppInfoData(
    locale: 'uz',
    version: 'v1.0.0 (So‘nggi versiya)',
    description: 'TOPIK GO — TOPIK II darajasiga erishish uchun mo‘ljallangan global ta’lim platformasi.',
    featuresTitle: 'Asosiy imkoniyatlar',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: 'Bo‘limlar bo‘yicha mashq',
        description: 'O‘qish · Eshitish · Yozish',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: 'Sinov imtihoni',
        description: 'Imtihon taymeri va OMR baholash',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: 'Aqlli lug‘at va grammatika',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: 'Ona tilida qo‘llab-quvvatlash',
        description: '9 ta til va oflayn ta’lim',
      ),
    ],
    techTitle: 'Texnologiyalar',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: 'Tushundim',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // Russian (러시아어)
  // -------------------------------------------------------------
  static const AppInfoData _ru = AppInfoData(
    locale: 'ru',
    version: 'v1.0.0 (Последняя версия)',
    description: 'TOPIK GO — глобальная платформа для успешной сдачи экзамена TOPIK II.',
    featuresTitle: 'Основные функции',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: 'Практика по разделам',
        description: 'Чтение · Аудирование · Письмо',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: 'Пробный экзамен',
        description: 'Таймер экзамена и оценка OMR',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: 'Умный словарь и грамматика',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: 'Родной язык и офлайн',
        description: '9 языков и обучение без интернета',
      ),
    ],
    techTitle: 'Технологии',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: 'Понятно',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // Vietnamese (베트남어)
  // -------------------------------------------------------------
  static const AppInfoData _vi = AppInfoData(
    locale: 'vi',
    version: 'v1.0.0 (Phiên bản mới nhất)',
    description: 'TOPIK GO là nền tảng học tập toàn cầu giúp bạn đạt được cấp độ TOPIK II mục tiêu.',
    featuresTitle: 'Tính năng chính',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: 'Luyện tập theo kỹ năng',
        description: 'Đọc · Nghe · Viết',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: 'Thi thử thực tế',
        description: 'Đồng hồ đếm giờ & Chấm điểm OMR',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: 'Từ vựng & Ngữ pháp thông minh',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: 'Hỗ trợ tiếng mẹ đẻ',
        description: '9 ngôn ngữ & Học ngoại tuyến',
      ),
    ],
    techTitle: 'Công nghệ',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: 'Đồng ý',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // Chinese (중국어)
  // -------------------------------------------------------------
  static const AppInfoData _zh = AppInfoData(
    locale: 'zh',
    version: 'v1.0.0 (最新版本)',
    description: 'TOPIK GO 是助您攻克 TOPIK II 目标等级的全球化备考平台。',
    featuresTitle: '核心功能',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: '分项真题练习',
        description: '阅读 · 听力 · 写作',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: '全真模拟考试',
        description: '考试计时 & OMR 阅卷',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: '智能词汇与语法',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: '母语对照支持',
        description: '9 种语言与离线学习',
      ),
    ],
    techTitle: '技术栈',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: '我知道了',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // Japanese (일본어)
  // -------------------------------------------------------------
  static const AppInfoData _ja = AppInfoData(
    locale: 'ja',
    version: 'v1.0.0 (最新バージョン)',
    description: 'TOPIK GOはTOPIK IIの目標級合格をサポートするグローバル学習プラットフォームです。',
    featuresTitle: '主な機能',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: '領域別過去問練習',
        description: '読解 · 聞き取り · 書き取り',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: '本番模擬試験',
        description: '試験タイマー & OMR採点',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: 'スマート単語・文法',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: '母国語サポート',
        description: '9言語対応 & オフライン学習',
      ),
    ],
    techTitle: '技術スタック',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: '確認',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // French (프랑스어)
  // -------------------------------------------------------------
  static const AppInfoData _fr = AppInfoData(
    locale: 'fr',
    version: 'v1.0.0 (Dernière version)',
    description: 'TOPIK GO est une plateforme mondiale pour réussir votre niveau cible au TOPIK II.',
    featuresTitle: 'Fonctionnalités principales',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: 'Pratique par domaine',
        description: 'Lecture · Écoute · Écriture',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: 'Examen blanc réel',
        description: 'Chronomètre & Notation OMR',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: 'Vocabulaire & Grammaire',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: 'Support multilingue',
        description: '9 langues & Étude hors ligne',
      ),
    ],
    techTitle: 'Technologies',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: 'D\'accord',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );

  // -------------------------------------------------------------
  // German (독일어)
  // -------------------------------------------------------------
  static const AppInfoData _de = AppInfoData(
    locale: 'de',
    version: 'v1.0.0 (Neueste Version)',
    description: 'TOPIK GO ist eine globale Lernplattform zum Erreichen Ihrer TOPIK II-Zielstufe.',
    featuresTitle: 'Hauptfunktionen',
    features: [
      AppInfoFeatureItem(
        icon: Icons.auto_stories_outlined,
        title: 'Bereichstraining',
        description: 'Lesen · Hören · Schreiben',
      ),
      AppInfoFeatureItem(
        icon: Icons.timer_outlined,
        title: 'Probeprüfung',
        description: 'Prüfungstimer & OMR-Bewertung',
      ),
      AppInfoFeatureItem(
        icon: Icons.translate_outlined,
        title: 'Smart Vokabeln & Grammatik',
        description: 'OneVoca & OneGrammar',
      ),
      AppInfoFeatureItem(
        icon: Icons.public_outlined,
        title: 'Muttersprachlicher Support',
        description: '9 Sprachen & Offline-Lernen',
      ),
    ],
    techTitle: 'Technologie-Stack',
    techInfo: 'Flutter 3.41 / Dart 3.11',
    confirmButton: 'Verstanden',
    copyright: '© 2026 TopikGo Team. All rights reserved.',
  );
}
