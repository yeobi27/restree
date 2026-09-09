import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';

/// 02. 로그인 — 카카오 / Google / Apple + 이메일.
///
/// TODO: 실제 연동은 kakao_flutter_sdk_user / google_sign_in / sign_in_with_apple.
/// 카카오는 Cloud Functions에서 Custom Token을 발급받아 Firebase Auth와 연결한다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.eco, size: 88, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('RESTREE',
                  style: TextStyle(fontSize: 24, letterSpacing: 5, color: AppColors.brandGold)),
              const SizedBox(height: 24),
              Text('당신의 기록을\n안전하게 보관해드릴게요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(flex: 2),
              _SocialButton(
                label: '카카오로 시작하기',
                background: const Color(0xFFFEE500),
                foreground: Colors.black87,
                onTap: () => context.go('/home'),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Google로 시작하기',
                background: Colors.white,
                foreground: Colors.black87,
                bordered: true,
                onTap: () => context.go('/home'),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Apple로 시작하기',
                background: Colors.white,
                foreground: Colors.black87,
                bordered: true,
                onTap: () => context.go('/home'),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('또는', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                // TODO: 이메일 가입/로그인 화면 미구현
                onPressed: () {},
                child: const Text('이메일로 시작하기',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('계정이 있으신가요?', style: Theme.of(context).textTheme.bodySmall),
                  TextButton(
                    onPressed: () {},
                    child: const Text('로그인',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool bordered;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          side: bordered ? const BorderSide(color: AppColors.divider) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
