import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';
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
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
