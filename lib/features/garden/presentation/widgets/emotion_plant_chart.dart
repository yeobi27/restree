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

  static const _minHeight = 40.0;
  static const _maxHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    // 최대 비율을 기준으로 정규화해 편차가 작아도 높이 차이가 보이게 한다.
    final maxPct = distribution.values
        .map((c) => c.percentage)
        .fold<double>(0.01, (a, b) => b > a ? b : a);

    return Column(
      children: [
        SizedBox(
          height: _maxHeight + 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: Emotion.values.map((e) {
              final pct = distribution[e]?.percentage ?? 0;
              final height = _minHeight + (_maxHeight - _minHeight) * (pct / maxPct);
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
              size: 30,
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
