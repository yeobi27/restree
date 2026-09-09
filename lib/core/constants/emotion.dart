import 'package:flutter/material.dart';

/// 설계서 §11 — 감정 enum 5종 고정.
/// 목업 기준 좌→우 배치 순서가 곧 enum 선언 순서다(좋음 → 힘듦).
enum Emotion { good, comfortable, normal, tired, hard }

extension EmotionX on Emotion {
  /// 통계 화면·아카이브 필터에서 쓰는 한글 라벨.
  ///
  /// 주의: 03단계(감정 선택) 화면에는 이 라벨을 표시하지 않는다 — v1.2 §9에서
  /// 아이콘 하단 텍스트 라벨을 제거하기로 확정. 단, 접근성을 위해 Semantics
  /// label로는 계속 사용한다.
  String get label => switch (this) {
        Emotion.good => '좋음',
        Emotion.comfortable => '편안함',
        Emotion.normal => '보통',
        Emotion.tired => '지침',
        Emotion.hard => '힘듦',
      };

  /// "나의 나무" 나뭇잎 시각 타입 (records.leafType 캐시값과 대응)
  String get leafDescription => switch (this) {
        Emotion.good => '밝은 잎 + 꽃',
        Emotion.comfortable => '연한 초록 잎',
        Emotion.normal => '옅은 잎',
        Emotion.tired => '처진 잎',
        Emotion.hard => '잎이 적어짐',
      };

  /// "감정 정원" 식물 성장 가이드 문구
  String get plantDescription => switch (this) {
        Emotion.good => '꽃이 활짝 피어요',
        Emotion.comfortable => '잎이 싱그럽게 자라요',
        Emotion.normal => '작은 새싹이 자라요',
        Emotion.tired => '잎이 조금 처져있어요',
        Emotion.hard => '쉬어가는 시간이에요',
      };

  /// 목업 스크린샷에서 추출한 감정 컬러.
  /// 감정 정원 캘린더 히트맵(v1.2 §8.2)과 아카이브 리스트 아이콘에 공통 사용.
  Color get color => switch (this) {
        Emotion.good => const Color(0xFFF4A9BE),
        Emotion.comfortable => const Color(0xFFB5CF95),
        Emotion.normal => const Color(0xFFF7C948),
        Emotion.tired => const Color(0xFFE08A5F),
        Emotion.hard => const Color(0xFFF4665A),
      };

  static Emotion fromKey(String key) =>
      Emotion.values.firstWhere((e) => e.name == key, orElse: () => Emotion.normal);
}

/// statsPeriodic.emotionDistribution 의 값 타입 — map<emotion,{count,percentage}>
class EmotionCount {
  final int count;
  final double percentage; // 0.0 ~ 1.0

  const EmotionCount({required this.count, required this.percentage});

  factory EmotionCount.fromJson(Map<String, dynamic> json) => EmotionCount(
        count: json['count'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {'count': count, 'percentage': percentage};
}
