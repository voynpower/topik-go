import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:topik_go/app/theme/app_colors.dart';
import 'package:topik_go/features/auth/application/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onInputChanged);
    _emailController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
    _confirmPasswordController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    return _nicknameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _agreeTerms &&
        _agreePrivacy;
  }

  Future<void> _register() async {
    if (!_isFormValid) return;

    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref
        .read(authControllerProvider)
        .register(email, password, nickname);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStateNotifier = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '회원 가입하기',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel('사용자명'),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  hintText: '사용자명',
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('이메일'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: '이메일',
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('비밀번호'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('비밀번호 확인'),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: '비밀번호 확인',
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              if (_confirmPasswordController.text.isNotEmpty &&
                  _passwordController.text != _confirmPasswordController.text)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '비밀번호가 일치하지 않습니다.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 32),
              const Text(
                '약관 동의',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildAgreementItem(
                label: '이용약관에 동의합니다',
                isRequired: true,
                value: _agreeTerms,
                onChanged: (v) => setState(() => _agreeTerms = v!),
              ),
              _buildAgreementItem(
                label: '개인정보 처리방침에 동의합니다',
                isRequired: true,
                value: _agreePrivacy,
                onChanged: (v) => setState(() => _agreePrivacy = v!),
              ),
              _buildAgreementItem(
                label: '마케팅 정보 수신에 동의합니다',
                isRequired: false,
                value: _agreeMarketing,
                onChanged: (v) => setState(() => _agreeMarketing = v!),
              ),
              const SizedBox(height: 32),
              ValueListenableBuilder<AsyncValue<void>>(
                valueListenable: authStateNotifier,
                builder: (context, authState, _) {
                  final isLoading = authState is AsyncLoading;

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: (_isFormValid && !isLoading) ? _register : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? AppColors.mint
                            : const Color(0xFFE5E7EB),
                        foregroundColor:
                            _isFormValid ? Colors.white : const Color(0xFF9CA3AF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
              ValueListenableBuilder<AsyncValue<void>>(
                valueListenable: authStateNotifier,
                builder: (context, authState, _) {
                  return authState.maybeWhen(
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          error.toString(),
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildAgreementItem({
    required String label,
    required bool isRequired,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                shape: const CircleBorder(),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                activeColor: AppColors.mint,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isRequired ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isRequired ? '필수' : '선택',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 36, bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '내용 보기',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mint,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
