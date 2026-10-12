// 최종 수정: 2026-10-12
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/core/utils/periods.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/presentation/providers/period_anchor_provider.dart';

/// 주/월/연 탭의 한 페이지 — 위에 "‹ 기간 ›" 이동 막대, 아래에 그 기간의 내용.
///
/// 이동 막대를 내용 영역 **바깥**에 둔 이유: 기록이 없는 기간은 내용이 통째로
/// EmptyState로 바뀌는데, 막대가 안쪽에 있으면 그때 화살표도 같이 사라져서
/// 다른 기간으로 돌아올 수 없게 된다.
class PeriodPage extends ConsumerWidget {
  const PeriodPage({
    super.key,
    required this.screen,
    required this.type,
    required this.builder,
  });

  /// 'tree'(나의 나무) / 'garden'(감정 정원) — 화면마다 보고 있는 기간을 따로 기억한다.
  final String screen;
  final PeriodType type;

  /// 기준 날짜를 받아 그 기간의 내용을 그린다.
  final Widget Function(DateTime anchor) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navKey = (screen, type);
    final anchor = ref.watch(periodAnchorProvider(navKey));

    final range = switch (type) {
      PeriodType.week => weekRangeOf(anchor),
      PeriodType.month => monthRangeOf(anchor),
      PeriodType.year => yearRangeOf(anchor),
    };
    final label = switch (type) {
      PeriodType.week => weekLabel(range),
      PeriodType.month => '${range.start.year}년 ${range.start.month}월',
      PeriodType.year => '${range.start.year}년',
    };

    // 오늘이 이 기간 안에 있으면 더 미래로는 갈 수 없다(미래 기간엔 기록이 없다).
    final canGoNext = range.end.isBefore(viewToday());

    void move(int delta) {
      ref.read(periodAnchorProvider(navKey).notifier).update((a) => switch (type) {
            PeriodType.week => shiftWeek(a, delta),
            PeriodType.month => shiftMonth(a, delta),
            PeriodType.year => shiftYear(a, delta),
          });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => move(-1),
                color: AppColors.primary,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: canGoNext ? () => move(1) : null,
                color: AppColors.primary,
                disabledColor: AppColors.divider,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(child: builder(anchor)),
      ],
    );
  }
}
