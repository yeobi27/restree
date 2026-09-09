/// 설계서 v1.3 §4 — 상점(재화) 시스템.

enum ShopCategory { font, background, particle, effect, bundle }

extension ShopCategoryX on ShopCategory {
  String get label => switch (this) {
        ShopCategory.font => '폰트',
        ShopCategory.background => '배경',
        ShopCategory.particle => '파티클',
        ShopCategory.effect => '이펙트',
        ShopCategory.bundle => '패키지',
      };

  static ShopCategory fromKey(String key) =>
      ShopCategory.values.firstWhere((e) => e.name == key, orElse: () => ShopCategory.font);
}

/// users/{uid}/wallet — 잔액은 서버(Cloud Functions)만 갱신 가능.
/// 클라이언트는 read 전용 (v1.3 §5 Security Rules).
class Wallet {
  final int balance;
  final DateTime updatedAt;

  const Wallet({required this.balance, required this.updatedAt});

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        balance: json['balance'] as int? ?? 0,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// shopCatalog/{itemId} — 전역 카탈로그, 사용자 쓰기 불가.
class ShopItem {
  final String itemId;
  final String name;
  final ShopCategory category;
  final int price;
  final String previewImageUrl;
  final String assetRef;
  final String? description;
  final List<String> bundleItemIds;

  const ShopItem({
    required this.itemId,
    required this.name,
    required this.category,
    required this.price,
    required this.previewImageUrl,
    required this.assetRef,
    this.description,
    this.bundleItemIds = const [],
  });

  factory ShopItem.fromJson(String itemId, Map<String, dynamic> json) => ShopItem(
        itemId: itemId,
        name: json['name'] as String,
        category: ShopCategoryX.fromKey(json['category'] as String),
        price: json['price'] as int? ?? 0,
        previewImageUrl: json['previewImageUrl'] as String? ?? '',
        assetRef: json['assetRef'] as String? ?? '',
        description: json['description'] as String?,
        bundleItemIds: (json['bundleItemIds'] as List?)?.cast<String>() ?? const [],
      );
}

/// users/{uid}/equippedItems — 현재 적용 중인 꾸미기.
/// v1.3 §4.4에 따라 적용 대상은 "일기 상세보기" 화면 한정.
class EquippedItems {
  final String? activeFont;
  final String? activeBackground;
  final String? activeEffectPack;

  const EquippedItems({this.activeFont, this.activeBackground, this.activeEffectPack});

  factory EquippedItems.fromJson(Map<String, dynamic> json) => EquippedItems(
        activeFont: json['activeFont'] as String?,
        activeBackground: json['activeBackground'] as String?,
        activeEffectPack: json['activeEffectPack'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'activeFont': activeFont,
        'activeBackground': activeBackground,
        'activeEffectPack': activeEffectPack,
      };
}
