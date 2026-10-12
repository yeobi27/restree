// 최종 수정: 2026-10-12
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/auth/data/auth_service.dart';
import 'package:restree/features/auth/presentation/providers/auth_providers.dart';

/// 02. 로그인 — Google(웹) 동작 / 카카오·Apple은 준비 중.
///
/// 로그인에 성공하면 라우터가 로그인 상태 변화를 감지해서 홈으로 보낸다
/// (app_router.dart의 redirect). 이 화면이 직접 이동시키지 않는다.
///
/// TODO: 카카오는 kakao_flutter_sdk_user 로그인 후 Cloud Functions에서 Custom Token을
/// 발급받아 Firebase Auth와 연결한다. Apple은 sign_in_with_apple(유료 개발자 계정 필요).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 로그인 동작을 감싸서 중복 클릭을 막고, 오류를 문구로 보여준다.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _snack(authErrorMessage(e));
    } finally {
      // 로그인에 성공하면 라우터가 이 화면을 치우므로 mounted를 확인한다.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

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
                onTap: _busy ? null : () => _snack('카카오 로그인은 준비 중이에요.'),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Google로 시작하기',
                background: Colors.white,
                foreground: Colors.black87,
                bordered: true,
                onTap: _busy ? null : () => _run(auth.signInWithGoogle),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Apple로 시작하기',
                background: Colors.white,
                foreground: Colors.black87,
                bordered: true,
                onTap: _busy ? null : () => _snack('Apple 로그인은 준비 중이에요.'),
              ),
              if (_busy) ...[
                const SizedBox(height: 20),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const SizedBox(height: 20),
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
              const SizedBox(height: 8),
              TextButton(
                // TODO: 이메일 가입/로그인 화면 미구현
                onPressed: _busy ? null : () => _snack('이메일 로그인은 준비 중이에요.'),
                child: const Text('이메일로 시작하기',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              // 개발 중에만 보이는 버튼: 팝업 없이 임시(익명) 계정으로 바로 시작한다.
              // 릴리스 빌드에서는 kDebugMode가 false라서 코드에 남아 있어도 화면에 나오지 않는다.
              if (kDebugMode)
                TextButton(
                  onPressed: _busy ? null : () => _run(auth.signInAnonymouslyForDev),
                  child: const Text('개발용: 익명으로 시작',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              const Spacer(),
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

  /// null이면 비활성(로그인 진행 중)
  final VoidCallback? onTap;

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
          disabledBackgroundColor: background.withOpacity(0.5),
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
