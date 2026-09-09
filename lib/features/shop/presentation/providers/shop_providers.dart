import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restree/features/shop/domain/entities/shop_models.dart';

/// TODO: Firebase 연동 시 Firestore(wallet, shopCatalog, inventory) 구독으로 교체.
/// 잔액 변경과 아이템 구매는 반드시 Cloud Functions를 거쳐야 한다 (v1.3 §4.2).

final walletProvider = FutureProvider<Wallet>((ref) async {
  return Wallet(balance: 0, updatedAt: DateTime.now());
});

final shopCatalogProvider = FutureProvider<List<ShopItem>>((ref) async {
  // 카탈로그는 관리자만 등록 가능한 전역 컬렉션이다.
  // 아래는 화면 확인용 더미 — 실제 상품/가격 정책은 미정(v1.3 §6.3).
  return const [
    ShopItem(
      itemId: 'font_serif_warm',
      name: '따뜻한 명조',
      category: ShopCategory.font,
      price: 100,
      previewImageUrl: '',
      assetRef: 'fonts/warm_serif.ttf',
      description: '일기를 볼 때 부드러운 세리프 폰트로 표시돼요.',
    ),
    ShopItem(
      itemId: 'bg_letter_paper',
      name: '편지지 배경',
      category: ShopCategory.background,
      price: 150,
      previewImageUrl: '',
      assetRef: 'backgrounds/letter.png',
      description: '일기 상세보기 배경이 편지지로 바뀌어요.',
    ),
    ShopItem(
      itemId: 'pack_spring',
      name: '봄날 패키지',
      category: ShopCategory.bundle,
      price: 300,
      previewImageUrl: '',
      assetRef: '',
      description: '폰트 + 배경 + 벚꽃 파티클 묶음',
      bundleItemIds: ['font_serif_warm', 'bg_letter_paper', 'particle_petal'],
    ),
  ];
});

final inventoryProvider = FutureProvider<Set<String>>((ref) async => <String>{});

final equippedItemsProvider = FutureProvider<EquippedItems>((ref) async {
  return const EquippedItems();
});
