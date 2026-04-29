import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrapRoute();
  }

  Future<void> _bootstrapRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(PrefsKeys.onboardingCompleted) ?? false;

    if (!mounted) return;
    context.go(completed ? '/auth/login' : '/language');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flutter_dash,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TOPIK GO',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.mintDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
