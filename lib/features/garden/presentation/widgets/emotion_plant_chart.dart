// 최종 수정: 2026-10-19
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/theme/app_colors.dart';

/// 감정 정원 월간/연간 — 감정 비율을 식물 "높이"로 표현하는 그래프.
/// 설계서 v1.2 §8.1 렌더링 규칙:
///  - 좋음 → 편안함 → 보통 → 지침 → 힘듦 순서로 좌→우 고정 배치
///  - 높이는 percentage에 비례
///  - 식물 종류는 §11 감정 식물 가이드 매핑을 재사용
class EmotionPlantChart extends StatelessWidget {
  final Map<Emotion, EmotionCount> distribution;

  const EmotionPlantChart({super.key, required this.distribution});

  /// 가장 많은 감정의 식물 높이
  static const _maxHeight = 150.0;

  /// 1일이라도 있으면 보이게 하는 최소 높이(작은 새싹). 최대 높이의 12% 정도라,
  /// 가장 많은 감정 대비 12% 미만인 감정만 실제보다 약간 크게 보인다.
  static const _sproutHeight = 18.0;

  /// 식물 높이 = 최대 높이 × (이 감정 일수 ÷ 가장 많은 감정 일수).
  ///
  /// 일수에 정확히 비례하게 해서 비슷한 일수는 비슷한 높이로 보이게 한다.
  /// (예: 좋음 16일, 지침 15일 → 150px, 약 141px로 거의 같은 높이)
  /// 이전에는 모든 식물에 기본 높이 40px을 깔아서, 적은 일수가 실제보다 크게 보이고
  /// 0일인 감정에도 식물이 그려졌다.
  static double plantHeight(double pct, double maxPct) {
    if (pct <= 0 || maxPct <= 0) return 0; // 0일이면 식물을 그리지 않는다
    return math.max(_sproutHeight, _maxHeight * pct / maxPct);
  }

  @override
  Widget build(BuildContext context) {
    final maxPct = distribution.values
        .map((c) => c.percentage)
        .fold<double>(0, (a, b) => b > a ? b : a);

    return Column(
      children: [
        SizedBox(
          height: _maxHeight + 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: Emotion.values.map((e) {
              final pct = distribution[e]?.percentage ?? 0;
              final height = plantHeight(pct, maxPct);
              return _Plant(emotion: e, height: height);
            }).toList(),
          ),
        ),
        // 흙 라인
        Container(height: 10, color: AppColors.soil),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Emotion.values.map((e) {
            final count = distribution[e] ?? const EmotionCount(count: 0, percentage: 0);
            return Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: e.color,
                  child: Icon(
                    switch (e) {
                      Emotion.good || Emotion.comfortable => Icons.sentiment_satisfied,
                      Emotion.normal => Icons.sentiment_neutral,
                      Emotion.tired => Icons.sentiment_dissatisfied,
                      Emotion.hard => Icons.sentiment_very_dissatisfied,
                    },
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${count.count}일',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('(${(count.percentage * 100).round()}%)',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Plant extends StatelessWidget {
  final Emotion emotion;
  final double height;

  const _Plant({required this.emotion, required this.height});

  @override
  Widget build(BuildContext context) {
    // TODO: 목업의 식물 일러스트(꽃/잎/새싹) 에셋으로 교체.
    // emotion.plantDescription 이 각 단계의 시각 의도를 담고 있다.
    // 에셋으로 바꿀 때도 "몇 단계 그림 중 하나"가 아니라 높이에 비례해 크기를 바꾸는 방식을
    // 유지해야 통계가 정확하게 보인다(단계로 나누면 경계 근처의 작은 차이가 크게 보인다).
    if (height <= 0) return const SizedBox(width: 48); // 0일: 식물 없음

    // 작은 식물은 아이콘도 작게 — 아이콘이 높이보다 크면 화면이 넘친다.
    final iconSize = math.min(30.0, height);

    return Semantics(
      label: '${emotion.label}: ${emotion.plantDescription}',
      child: SizedBox(
        width: 48,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              emotion == Emotion.good ? Icons.local_florist : Icons.grass,
              color: emotion == Emotion.good ? emotion.color : AppColors.primaryLight,
              size: iconSize,
            ),
            Expanded(
              child: Container(width: 3, color: AppColors.primaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
