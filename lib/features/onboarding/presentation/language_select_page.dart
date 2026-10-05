import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';

class LanguageSelectPage extends ConsumerStatefulWidget {
  const LanguageSelectPage({super.key});

  @override
  ConsumerState<LanguageSelectPage> createState() => _LanguageSelectPageState();
}

class _LanguageSelectPageState extends ConsumerState<LanguageSelectPage> {
  late String selected;

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentLanguageProvider);
    selected = current.isNotEmpty ? current : 'ko';
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = ref.read(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    final savedCode = prefs.getString(PrefsKeys.preferredLanguageCode);
    if (!mounted) return;

    if (savedCode != null && kSupportedLanguages.any((lang) => lang.code == savedCode)) {
      setState(() => selected = savedCode);
    }
  }

  Future<void> _onLanguageSelected(String code) async {
    setState(() => selected = code);
    await ref.read(currentLanguageProvider.notifier).setLanguage(code);
  }

  Future<void> _saveLanguageAndContinue() async {
    await ref.read(currentLanguageProvider.notifier).setLanguage(selected);
    final prefs = ref.read(sharedPreferencesProvider) ?? await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.onboardingCompleted, true);

    if (!mounted) return;
    context.go('/auth/login');
  }

  static String _getGreetingSubtitle(String code) {
    switch (code) {
      case 'ko':
        return '학습에 사용할 기본 언어를 선택하세요.';
      case 'uz':
        return "O'rganish uchun qulay tilni tanlang.";
      case 'ru':
        return 'Выберите удобный язык для обучения.';
      case 'vi':
        return 'Chọn ngôn ngữ bạn muốn sử dụng để học.';
      case 'zh':
        return '请选择您学习时希望使用的语言。';
      case 'ja':
        return '学習に使用する言語を選択してください。';
      case 'fr':
        return 'Choisissez la langue que vous souhaitez utiliser.';
      case 'de':
        return 'Wählen Sie Ihre bevorzugte Lernsprache.';
      case 'en':
      default:
        return 'Hello! Which language do you usually speak?';
    }
  }

  static String _getNextButtonLabel(String code, String fallback) {
    switch (code) {
      case 'ko':
        return '다음 단계';
      case 'uz':
        return 'Keyingi qadam';
      case 'ru':
        return 'Следующий шаг';
      case 'vi':
        return 'Tiếp tục';
      case 'zh':
        return '下一步';
      case 'ja':
        return '次へ';
      case 'fr':
        return 'Étape suivante';
      case 'de':
        return 'Nächster Schritt';
      case 'en':
        return 'Next Step';
      default:
        return fallback.isNotEmpty ? fallback : 'Next Step';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final greetingSubtitle = _getGreetingSubtitle(selected);
    final nextButtonLabel = _getNextButtonLabel(selected, strings.next);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.chooseLanguage,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your language',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.language_rounded, color: AppColors.mintDark, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.chooseLanguage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            greetingSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: kSupportedLanguages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = kSupportedLanguages[index];
                    final active = item.code == selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: active ? AppColors.mintDark : AppColors.border,
                          width: active ? 1.8 : 1.0,
                        ),
                      ),
                      tileColor: active ? AppColors.mint.withValues(alpha: 0.08) : AppColors.surface,
                      title: Text(
                        item.nativeName,
                        style: TextStyle(
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active ? AppColors.mintDark : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? AppColors.mintDark.withValues(alpha: 0.8) : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: active ? AppColors.mintDark : AppColors.textSecondary,
                      ),
                      onTap: () => _onLanguageSelected(item.code),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saveLanguageAndContinue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nextButtonLabel,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
