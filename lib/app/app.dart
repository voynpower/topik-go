import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/app/router.dart';
import 'package:topik_go/app/theme/app_theme.dart';
import 'package:topik_go/core/services/translation_service.dart';

class TopikGoApp extends ConsumerWidget {
  const TopikGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final currentLang = ref.watch(currentLanguageProvider);

    return MaterialApp.router(
      title: 'TOPIK GO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(currentLang),
      scrollBehavior: const _TopikScrollBehavior(),
      routerConfig: router,
    );
  }
}

class _TopikScrollBehavior extends MaterialScrollBehavior {
  const _TopikScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
