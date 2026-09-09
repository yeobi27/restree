import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';

/// 주간 탭 월~일 스트립 — 기록이 있는 요일은 나뭇잎, 없는 요일은 빈 원.
class WeeklyCalendarStrip extends StatelessWidget {
  final DateTime weekStart; // 월요일
  final List<DailyRecord> records;

  const WeeklyCalendarStrip({super.key, required this.weekStart, required this.records});

  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final recorded = {for (final r in records) r.date};

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final dateKey =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final has = recorded.contains(dateKey);

        return GestureDetector(
          onTap: has ? () => context.push('/record/detail/$dateKey') : null,
          child: Column(
            children: [
              Text(_labels[i], style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 17,
                backgroundColor: has ? AppColors.leafFilled : AppColors.leafEmpty,
                child: has ? const Icon(Icons.eco, size: 17, color: Colors.white) : null,
              ),
              const SizedBox(height: 6),
              Text('${day.day}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      }),
    );
  }
}
