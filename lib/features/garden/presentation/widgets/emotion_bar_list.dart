import 'package:flutter/material.dart';
import 'package:restree/core/constants/emotion.dart';

/// "이번 주/해의 마음 요약" — 감정별 가로 막대 목록.
/// (월간 탭은 막대 대신 EmotionPlantChart의 식물 높이로 표현한다)
class EmotionBarList extends StatelessWidget {
  final Map<Emotion, EmotionCount> distribution;
  final bool showDays;

  const EmotionBarList({super.key, required this.distribution, this.showDays = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Emotion.values.map((e) {
        final count = distribution[e] ?? const EmotionCount(count: 0, percentage: 0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              CircleAvatar(radius: 11, backgroundColor: e.color),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Text(e.label, style: Theme.of(context).textTheme.bodySmall),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: count.percentage,
                    minHeight: 9,
                    backgroundColor: e.color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(e.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: showDays ? 74 : 44,
                child: Text(
                  showDays
                      ? '${count.count}일 (${(count.percentage * 100).round()}%)'
                      : '${(count.percentage * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
