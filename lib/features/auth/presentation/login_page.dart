import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flutter_dash,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'LoroTOPIK',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.mintDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: const Text('Sign in with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Login with Kakao'),
              ),
              const SizedBox(height: 24),
              const Text('또는'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: '이메일',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: '비밀번호',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/main/home'),
                child: const Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
