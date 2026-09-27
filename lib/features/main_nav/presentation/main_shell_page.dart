import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index);
        },
        indicatorColor: AppColors.mint.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: strings.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            label: strings.navPractice,
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_note),
            label: strings.navMockExam,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: strings.navSettings,
          ),
        ],
      ),
    );
  }
}
