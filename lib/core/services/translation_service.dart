import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  final String code;
  final String name;
  final String nativeName;
}

const List<AppLanguage> kSupportedLanguages = [
  AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'uz', name: 'Uzbek', nativeName: "O'zbekcha"),
  AppLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
  AppLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
  AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
  AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
  AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
];

String getLanguageDisplayName(String? code) {
  final match = kSupportedLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => const AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
  );
  return '${match.nativeName} (${match.name})';
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// 현재 설정된 사용자 언어 코드를 관리하는 Notifier
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs != null) {
      final saved = prefs.getString(PrefsKeys.preferredLanguageCode);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } else {
      _initAsync();
    }
    return 'ko';
  }

  Future<void> _initAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(PrefsKeys.preferredLanguageCode);
    if (saved != null && saved.isNotEmpty && state != saved) {
      state = saved;
    }
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = ref.read(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.preferredLanguageCode, code);

    // 사용자 프로필이 있는 경우 백엔드에도 동기화
    try {
      await ref.read(userRepositoryProvider).updateProfile({'language_code': code});
      ref.invalidate(userProfileProvider);
    } catch (_) {
      // 오프라인이거나 비로그인 시 로컬 설정 유지
    }
  }

  /// 로그인/회원가입 후 로컬에서 선택한 언어를 백엔드 프로필에 동기화
  Future<void> syncWithProfile() async {
    final currentCode = state;
    if (currentCode.isEmpty) return;
    try {
      await ref.read(userRepositoryProvider).updateProfile({'language_code': currentCode});
      ref.invalidate(userProfileProvider);
    } catch (_) {
      // 오프라인이거나 비로그인 시 무시
    }
  }
}

final currentLanguageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

/// 외부 번역 서비스 (Google Translate 1순위 + MyMemory 백업 + HTML 엔티티 디코딩)
class TranslationService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// HTML 엔티티 (&#39;, &quot;, &amp; 등)를 올바른 문자로 디코딩
  static String unescapeHtml(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
          final code = int.tryParse(m.group(1) ?? '');
          return code != null ? String.fromCharCode(code) : m.group(0)!;
        })
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);', caseSensitive: false), (m) {
          final code = int.tryParse(m.group(1) ?? '', radix: 16);
          return code != null ? String.fromCharCode(code) : m.group(0)!;
        });
  }

  /// 1순위: Google Translate 단일 번역 (고품질 신경망 번역, 따옴표/아포스트로피 왜곡 방지)
  static Future<String?> _translateWithGoogle(String text, String targetLang) async {
    final response = await _dio.get(
      'https://translate.googleapis.com/translate_a/single',
      queryParameters: {
        'client': 'gtx',
        'sl': 'ko',
        'tl': targetLang,
        'dt': 't',
        'q': text,
      },
    );

    if (response.statusCode == 200 && response.data is List) {
      final list = response.data as List;
      if (list.isNotEmpty && list[0] is List) {
        final segments = list[0] as List;
        final buffer = StringBuffer();
        for (final seg in segments) {
          if (seg is List && seg.isNotEmpty && seg[0] != null) {
            buffer.write(seg[0].toString());
          }
        }
        final result = buffer.toString().trim();
        if (result.isNotEmpty && result.toLowerCase() != text.toLowerCase()) {
          return unescapeHtml(result);
        }
      }
    }
    return null;
  }

  /// 2순위: MyMemory 오픈 API 백업
  static Future<String?> _translateWithMyMemory(String text, String targetLang) async {
    final response = await _dio.get(
      'https://api.mymemory.translated.net/get',
      queryParameters: {
        'q': text,
        'langpair': 'ko|$targetLang',
      },
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final resData = response.data['responseData'];
      if (resData is Map<String, dynamic>) {
        final translated = resData['translatedText']?.toString().trim();
        if (translated != null &&
            translated.isNotEmpty &&
            !translated.startsWith('MYMEMORY WARNING') &&
            translated.toLowerCase() != text.toLowerCase()) {
          return unescapeHtml(translated);
        }
      }
    }
    return null;
  }

  /// 한국어 단어/문장을 대상 언어 코드로 번역
  static Future<String?> translate({
    required String text,
    required String targetLang,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    if (targetLang == 'ko') return clean;

    // 1. Google Translate 1순위
    try {
      final gResult = await _translateWithGoogle(clean, targetLang);
      if (gResult != null && gResult.isNotEmpty) {
        return gResult;
      }
    } catch (_) {}

    // 2. MyMemory 백업
    try {
      final mResult = await _translateWithMyMemory(clean, targetLang);
      if (mResult != null && mResult.isNotEmpty) {
        return mResult;
      }
    } catch (_) {}

    return null;
  }
}
