import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/shop/domain/entities/shop_models.dart';
import 'package:restree/features/shop/presentation/providers/shop_providers.dart';

/// 상점 — 재화로 꾸미기 아이템(폰트/배경/파티클/이펙트/패키지)을 구매한다.
/// 설계서 v1.3 §4.
///
/// TODO(미정, v1.3 §6.3):
///  - 재화 명칭·단위·환율, IAP 충전 상품 구성, 아이템 가격 정책
///  - 구매 아이템이 영구 소유인지 시즌제인지
///  - 상점 진입 경로 최종 확정(현재는 햄버거 메뉴 경유만 구현)
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final catalogAsync = ref.watch(shopCatalogProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('상점'),
      ),
      body: Column(
        children: [
          walletAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
            data: (wallet) => Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('보유 재화', style: TextStyle(fontSize: 15))),
                  Text('${wallet.balance}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    // TODO: in_app_purchase 연동 → Cloud Functions 영수증 검증 (v1.3 §4.2)
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('충전 기능은 준비 중입니다.')),
                    ),
                    child: const Text('충전'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: catalogAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (items) {
                final owned = inventoryAsync.valueOrNull ?? <String>{};
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ShopItemCard(
                    item: items[i],
                    owned: owned.contains(items[i].itemId),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool owned;

  const _ShopItemCard({required this.item, required this.owned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            // TODO: previewImageUrl 렌더링
            child: const Icon(Icons.palette_outlined, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.category.label,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(item.description!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          owned
              ? const Text('보유중', style: TextStyle(color: AppColors.textSecondary))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(72, 38),
                    padding: EdgeInsets.zero,
                  ),
                  // TODO: Cloud Functions purchaseShopItem 호출 (트랜잭션으로
                  // 잔액 차감 + inventory 추가) — 클라이언트가 직접 처리하지 않는다.
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('구매 기능은 준비 중입니다.')),
                  ),
                  child: Text('${item.price}'),
                ),
        ],
      ),
    );
  }
}
