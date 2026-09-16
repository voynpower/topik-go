import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/auth/session_store.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrapRoute();
  }

  Future<void> _bootstrapRoute() async {
    final startTime = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(PrefsKeys.onboardingCompleted) ?? false;
    final sessionStore = ref.read(sessionStoreProvider);
    final token = await sessionStore.readToken();

    bool isAuthenticated = false;

    if (token != null && token.isNotEmpty) {
      try {
        final userRepo = ref.read(userRepositoryProvider);
        await userRepo.getProfile();
        isAuthenticated = true;
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 401) {
          await sessionStore.clearToken();
          isAuthenticated = false;
        } else {
          // If network error/server offline, assume token is still valid
          isAuthenticated = true;
        }
      }
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remainingDelay = 1300 - elapsed;
    if (remainingDelay > 0) {
      await Future<void>.delayed(Duration(milliseconds: remainingDelay));
    }

    if (!mounted) return;

    if (isAuthenticated) {
      context.go('/main/home');
    } else {
      context.go(completed ? '/auth/login' : '/language');
    }
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

