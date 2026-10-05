import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/core/legal/legal_documents.dart';
import 'package:topik_go/core/legal/legal_modal.dart';
import 'package:topik_go/core/localization/app_strings_provider.dart';
import 'package:topik_go/core/services/translation_service.dart';
import 'package:topik_go/features/auth/application/auth_controller.dart';
import 'package:topik_go/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

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

  bool _isGoogleLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final strings = ref.read(appStringsProvider);

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_getRequiredFieldsMessage(strings.locale))));
      return;
    }

    final success = await ref
        .read(authControllerProvider)
        .login(email, password);

    if (success && mounted) {
      await ref.read(currentLanguageProvider.notifier).syncWithProfile();
      if (!mounted) return;
      ref.invalidate(userProfileProvider);
      context.go('/main/home');
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final success = await ref.read(authControllerProvider).loginWithGoogle();
      if (success && mounted) {
        await ref.read(currentLanguageProvider.notifier).syncWithProfile();
        if (!mounted) return;
        ref.invalidate(userProfileProvider);
        context.go('/main/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  static String _getGoogleLoginLabel(String code) {
    switch (code) {
      case 'uz': return 'Google orqali davom etish';
      case 'ru': return 'Продолжить с Google';
      case 'en': return 'Continue with Google';
      case 'vi': return 'Tiếp tục với Google';
      case 'zh': return '通过 Google 继续';
      case 'ja': return 'Google で続ける';
      case 'fr': return 'Continuer avec Google';
      case 'de': return 'Mit Google fortfahren';
      case 'ko':
      default: return 'Google 계정으로 계속하기';
    }
  }

  static String _getPasswordHint(String code) {
    switch (code) {
      case 'uz': return 'Parol';
      case 'ru': return 'Пароль';
      case 'en': return 'Password';
      case 'vi': return 'Mật khẩu';
      case 'zh': return '密码';
      case 'ja': return 'パスワード';
      case 'fr': return 'Mot de passe';
      case 'de': return 'Passwort';
      case 'ko':
      default: return '비밀번호';
    }
  }

  static String _getOrLabel(String code) {
    switch (code) {
      case 'uz': return 'yoki';
      case 'ru': return 'или';
      case 'en': return 'or';
      case 'vi': return 'hoặc';
      case 'zh': return '或';
      case 'ja': return 'または';
      case 'fr': return 'ou';
      case 'de': return 'oder';
      case 'ko':
      default: return '또는';
    }
  }

  static String _getLoginLabel(String code) {
    switch (code) {
      case 'uz': return 'Kirish';
      case 'ru': return 'Войти';
      case 'en': return 'Sign In';
      case 'vi': return 'Đăng nhập';
      case 'zh': return '登录';
      case 'ja': return 'ログイン';
      case 'fr': return 'Connexion';
      case 'de': return 'Anmelden';
      case 'ko':
      default: return '로그인';
    }
  }

  static String _getLoginFailedLabel(String code) {
    switch (code) {
      case 'uz': return 'Kirishda xatolik yuz berdi';
      case 'ru': return 'Ошибка входа';
      case 'en': return 'Login failed';
      case 'vi': return 'Đăng nhập thất bại';
      case 'zh': return '登录失败';
      case 'ja': return 'ログインに失敗しました';
      case 'fr': return 'Échec de connexion';
      case 'de': return 'Anmeldung fehlgeschlagen';
      case 'ko':
      default: return '로그인 실패';
    }
  }

  static String _getSignUpPrompt(String code) {
    switch (code) {
      case 'uz': return "Hisobingiz yo'qmi? Ro'yxatdan o'tish";
      case 'ru': return 'Нет аккаунта? Зарегистрироваться';
      case 'en': return "Don't have an account? Sign Up";
      case 'vi': return 'Chưa có tài khoản? Đăng ký';
      case 'zh': return '还没有账号？注册';
      case 'ja': return 'アカウントをお持ちでないですか？ 新規登録';
      case 'fr': return "Pas de compte ? S'inscrire";
      case 'de': return 'Kein Konto? Registrieren';
      case 'ko':
      default: return '계정이 없으신가요? 회원가입';
    }
  }

  static String _getRequiredFieldsMessage(String code) {
    switch (code) {
      case 'uz': return 'Elektron pochta va parolni kiriting.';
      case 'ru': return 'Пожалуйста, введите эл. почту и пароль.';
      case 'en': return 'Please enter your email and password.';
      case 'vi': return 'Vui lòng nhập email và mật khẩu.';
      case 'zh': return '请输入邮箱和密码。';
      case 'ja': return 'メールアドレスとパスワードを入力してください。';
      case 'fr': return 'Veuillez saisir votre e-mail et votre mot de passe.';
      case 'de': return 'Bitte geben Sie Ihre E-Mail und Ihr Passwort ein.';
      case 'ko':
      default: return '이메일과 비밀번호를 입력해주세요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStateNotifier = ref.watch(authStateProvider);
    final strings = ref.watch(appStringsProvider);
    final locale = strings.locale;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mintDark.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flutter_dash,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'TOPIK GO',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.mintDark,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),
              GoogleSignInButton(
                onPressed: _loginWithGoogle,
                isLoading: _isGoogleLoading,
                text: _getGoogleLoginLabel(locale),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _getOrLabel(locale),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.mail_outline),
                  hintText: strings.email,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: _getPasswordHint(locale),
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<AsyncValue<void>>(
                valueListenable: authStateNotifier,
                builder: (context, authState, _) {
                  return authState.when(
                    data: (_) => FilledButton(
                      onPressed: _login,
                      child: Text(_getLoginLabel(locale)),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Column(
                      children: [
                        Text(
                          '${_getLoginFailedLabel(locale)}: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _login,
                          child: Text(strings.retry),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/auth/register'),
                child: Text(_getSignUpPrompt(locale)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => showLegalModal(context, type: LegalDocumentType.termsOfService),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      strings.termsOfService,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: Colors.black26, fontSize: 11)),
                  TextButton(
                    onPressed: () => showLegalModal(context, type: LegalDocumentType.privacyPolicy),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      strings.privacyPolicy,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
