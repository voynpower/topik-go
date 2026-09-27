import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/localization/app_strings.dart';
import 'package:topik_go/core/services/translation_service.dart';

final appStringsProvider = Provider<AppStrings>((ref) {
  final currentLang = ref.watch(currentLanguageProvider);
  return AppStrings.of(currentLang);
});
