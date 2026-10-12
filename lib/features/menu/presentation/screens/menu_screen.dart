// 최종 수정: 2026-10-12
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/auth/data/auth_service.dart';
import 'package:restree/features/auth/presentation/providers/auth_providers.dart';
import 'package:restree/features/shop/presentation/providers/shop_providers.dart';

/// 좌측 상단 햄버거(☰) 진입 메뉴 페이지.
///
/// v1.4 §3.1 — 나의 나무/감정 정원에서 제거된 톱니바퀴(설정)가 여기로 들어온다.
/// TODO: 전체 메뉴 구성(IA)은 아직 미확정. 아래는 지금까지 문서에서 확인된
/// 항목만 배치한 잠정 목록이다.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final isAnonymous = user?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('메뉴'),
      ),
      body: ListView(
        children: [
          // 계정 — 익명(임시) 계정이면 Google 계정을 연결할 수 있다.
          ListTile(
            leading: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
            title: Text(
              user == null
                  ? '로그인 정보를 불러오는 중'
                  : isAnonymous
                      ? '임시 계정 (익명)'
                      : (user.email ?? user.displayName ?? '로그인됨'),
            ),
            subtitle: isAnonymous ? const Text('Google 계정을 연결하면 기록을 안전하게 보관할 수 있어요') : null,
          ),
          if (isAnonymous)
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Google 계정 연결'),
              onTap: () => _linkGoogle(context, ref),
            ),
          const Divider(),
          // 상점 진입 — v1.3 §4.3의 권장안(홈 상단 재화 뱃지)은 아직 미채택이라
          // 현재는 이 메뉴가 상점으로 가는 주 경로다.
          ListTile(
            leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
            title: const Text('상점'),
            subtitle: const Text('폰트 · 배경 · 이펙트 꾸미기'),
            trailing: wallet.maybeWhen(
              data: (w) => Text('${w.balance}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary)),
              orElse: () => const SizedBox.shrink(),
            ),
            onTap: () => context.push('/shop'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('설정'),
            // TODO: 설정 화면 세부 구성 미정 (알림 시간, 테마 등)
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('계정 관리'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () => _confirmSignOut(context, ref, isAnonymous: isAnonymous),
          ),
        ],
      ),
    );
  }

  Future<void> _linkGoogle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await ref.read(authServiceProvider).signInWithGoogle();
      switch (outcome) {
        case GoogleSignInOutcome.linkedAnonymous:
          messenger.showSnackBar(const SnackBar(content: Text('Google 계정이 연결됐어요. 기록은 그대로 유지돼요.')));
        case GoogleSignInOutcome.needsRetry:
          messenger.showSnackBar(const SnackBar(
              content: Text('이미 가입된 Google 계정이에요. 로그인 화면에서 Google로 다시 시작해 주세요.')));
        case GoogleSignInOutcome.signedIn:
        case GoogleSignInOutcome.cancelled:
          break;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref, {required bool isAnonymous}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        content: Text(isAnonymous
            ? '임시(익명) 계정은 로그아웃하면 이 계정의 기록을 다시 볼 수 없어요. 먼저 Google 계정을 연결해 두세요.'
            : '로그아웃해도 기록은 계정에 그대로 남아 있어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('로그아웃')),
        ],
      ),
    );
    // 로그아웃하면 라우터가 로그인 상태 변화를 감지해서 온보딩/로그인 화면으로 보낸다.
    if (ok == true) await ref.read(authServiceProvider).signOut();
  }
}
