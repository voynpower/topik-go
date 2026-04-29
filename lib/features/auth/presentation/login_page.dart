import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/auth/application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider)
        .login(email, password);

    if (success && mounted) {
      context.go('/main/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStateNotifier = ref.watch(authStateProvider);

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
                'TOPIK GO',
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Login with Kakao'),
                ),
              ),
              const SizedBox(height: 24),
              const Text('또는'),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: '이메일',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: '비밀번호',
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<AsyncValue<void>>(
                valueListenable: authStateNotifier,
                builder: (context, authState, _) {
                  return authState.when(
                    data: (_) => FilledButton(
                      onPressed: _login,
                      child: const Text('로그인'),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Column(
                      children: [
                        Text(
                          '로그인 실패: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _login,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/auth/register'),
                child: const Text('계정이 없으신가요? 회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
