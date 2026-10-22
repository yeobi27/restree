// 최종 수정: 2026-10-19
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/constants/layout.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/core/widgets/empty_state.dart';
import 'package:restree/features/auth/presentation/providers/auth_providers.dart';
import 'package:restree/core/utils/periods.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/presentation/widgets/month_calendar_sheet.dart';
import 'package:restree/features/tree/presentation/widgets/period_page.dart';
import 'package:restree/features/tree/presentation/widgets/weekly_calendar_strip.dart';

/// 09. 나의 나무 — 주간 / 월간 / 연간
///
/// v1.4 §3.1 — 우측 상단 톱니바퀴(설정) 아이콘은 제거되었다.
/// 설정은 좌측 상단 햄버거 메뉴를 통해서만 접근한다.
class MyTreeScreen extends StatelessWidget {
  const MyTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => context.push('/menu'),
          ),
          title: const Text('나의 나무'),
          bottom: const TabBar(
            tabs: [Tab(text: '주간'), Tab(text: '월간'), Tab(text: '연간')],
          ),
        ),
        body: TabBarView(
          children: [
            PeriodPage(screen: 'tree', type: PeriodType.week, builder: (a) => _WeeklyTab(anchor: a)),
            PeriodPage(screen: 'tree', type: PeriodType.month, builder: (a) => _MonthlyTab(anchor: a)),
            PeriodPage(screen: 'tree', type: PeriodType.year, builder: (a) => _YearlyTab(anchor: a)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── 주간 ───────────────────────────

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab({required this.anchor});

  /// PeriodPage가 정해 준 "지금 보고 있는 기간"의 기준 날짜
  final DateTime anchor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = weekRangeOf(anchor);
    final weekStart = week.start;
    final weekEnd = week.end;
    final statsAsync = ref.watch(statsPeriodicProvider((PeriodType.week, week.key)));
    final recordsAsync = ref.watch(recordsInRangeProvider((weekStart, weekEnd)));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        if (stats.isEmpty) return const EmptyState();
        return recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류: $e')),
          data: (records) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20 + kFabClearance),
            children: [
              const SizedBox(height: 12),
              Center(child: Text('이번 주의 나무', style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 16),
              // TODO: weeklyTreeStage("4~5일" 등)에 대응하는 나무 일러스트 에셋 연결
              const Icon(Icons.park, size: 140, color: AppColors.leafFilled),
              const SizedBox(height: 12),
              Center(
                child: Text('${stats.daysRecorded}일 동안 기록했어요',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(height: 24),
              WeeklyCalendarStrip(weekStart: weekStart, records: records),
              const SizedBox(height: 24),
              _StatCard(title: '이번 주의 성장', rows: [
                ('기록한 날', '${stats.daysRecorded}일'),
                ('연속 기록', '${stats.streakAtPeriodEnd}일'),
                ('가장 많이 느낀 감정', stats.dominantEmotion?.label ?? '-'),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── 월간 ───────────────────────────

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab({required this.anchor});

  final DateTime anchor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthRange = monthRangeOf(anchor);
    final month = monthRange.start;
    final statsAsync = ref.watch(statsPeriodicProvider((PeriodType.month, monthRange.key)));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        if (stats.isEmpty) return const EmptyState();
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20 + kFabClearance),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.park, size: 160, color: AppColors.leafFilled),
            const SizedBox(height: 24),
            _StatCard(title: '${month.month}월의 기록', rows: [
              ('기록한 날', '${stats.daysRecorded} / $daysInMonth일'),
              // v1.2에서 추가한 longestStreakInPeriod — 목업의 "최고 연속 기록"
              ('최고 연속 기록', '${stats.longestStreakInPeriod}일'),
            ]),
            const SizedBox(height: 16),
            _NavCard(
              icon: Icons.calendar_month_outlined,
              label: '기록 날짜 보기',
              // 나의 나무는 기록 유무만 표시 (감정색 아님)
              onTap: () => showMonthCalendarSheet(context,
                  month: month, mode: CalendarColorMode.tree),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────── 연간 ───────────────────────────

class _YearlyTab extends ConsumerWidget {
  const _YearlyTab({required this.anchor});

  final DateTime anchor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearRange = yearRangeOf(anchor);
    final year = yearRange.start.year;
    final statsAsync = ref.watch(statsPeriodicProvider((PeriodType.year, yearRange.key)));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        if (stats.isEmpty) return const EmptyState();
        final busiest = stats.busiestMonth;
        // "올해의 N%" — 진행 중인 해는 오늘까지, 지난 해는 연말까지의 일수로 나눈다.
        final t = viewAnchor();
        final today = DateTime(t.year, t.month, t.day);
        final effectiveEnd = today.isBefore(stats.periodEnd) ? today : stats.periodEnd;
        final elapsed = effectiveEnd.difference(stats.periodStart).inDays + 1;
        final percent = ((stats.daysRecorded / elapsed) * 100).clamp(0, 100).round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20 + kFabClearance),
          children: [
            const SizedBox(height: 20),
            Center(child: Text('$year년의 나무', style: Theme.of(context).textTheme.headlineSmall)),
            const SizedBox(height: 16),
            // periodTreeLevel(연도 기준 나무 단계)에 대응하는 일러스트
            const Icon(Icons.forest, size: 170, color: AppColors.leafFilled),
            const SizedBox(height: 16),
            Center(
              child: Text('${stats.daysRecorded}일 기록했어요',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 24),
            _StatCard(title: '${stats.periodKey}년의 기록 요약', rows: [
              ('기록한 날', '${stats.daysRecorded}일 (올해의 $percent%)'),
              if (busiest != null)
                ('가장 오래 기록한 달', '${busiest.month}월 · ${busiest.daysRecorded}일'),
              ('가장 많이 느낀 감정', stats.dominantEmotion?.label ?? '-'),
              ('연속 기록 최장', '${stats.longestStreakInPeriod}일'),
            ]),
            const SizedBox(height: 16),
            _MonthlyBreakdownCard(year: year, months: stats.monthlyBreakdown),
          ],
        );
      },
    );
  }
}

/// 연간 탭 "월별 기록 현황" — monthlyBreakdown[].density 로 잎 크기를 달리한다.
class _MonthlyBreakdownCard extends ConsumerWidget {
  final int year;
  final List<MonthlySummary> months;

  const _MonthlyBreakdownCard({required this.year, required this.months});

  /// 화면의 잎과 범례가 같은 크기를 쓴다. (이전에는 범례만 작게 그려서
  /// 실제 "적음" 잎이 범례의 "보통"처럼 보였다)
  static double _sizeOf(MonthLeaf leaf) => switch (leaf) {
        MonthLeaf.high => 28,
        MonthLeaf.medium => 22,
        MonthLeaf.low || MonthLeaf.none || MonthLeaf.notYet => 16,
      };

  static Widget _leaf(MonthLeaf leaf) => switch (leaf) {
        MonthLeaf.notYet => const Icon(Icons.circle_outlined, size: 10, color: AppColors.leafEmpty),
        MonthLeaf.none => Icon(Icons.eco_outlined, size: _sizeOf(leaf), color: AppColors.divider),
        _ => Icon(Icons.eco, size: _sizeOf(leaf), color: AppColors.leafFilled),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(accountStartDateProvider);
    final today = viewToday();
    final daysByMonth = {for (final m in months) m.month: m.daysRecorded};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월별 기록 현황', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          // TODO: 목업은 나무를 중심으로 12개월이 원형 배치 — 지금은 단순 그리드로 대체
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(12, (i) {
              final month = i + 1;
              final leaf = monthLeafOf(
                daysByMonth[month] ?? 0,
                recordableDaysInMonth(year, month, startDate: start, today: today),
              );
              return SizedBox(
                width: 56,
                child: Column(
                  children: [
                    // 잎 크기가 달라도 월 이름 줄이 흔들리지 않게 높이를 고정한다.
                    SizedBox(height: 30, child: Center(child: _leaf(leaf))),
                    const SizedBox(height: 4),
                    Text(
                      '$month월',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: leaf == MonthLeaf.notYet ? AppColors.leafEmpty : null,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (leaf, label) in const [
                (MonthLeaf.high, '기록 많음'),
                (MonthLeaf.medium, '보통'),
                (MonthLeaf.low, '기록 적음'),
                (MonthLeaf.none, '기록 없음'),
              ])
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _leaf(leaf),
                  const SizedBox(width: 4),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ]),
            ],
          ),
          // const SizedBox(height: 8),
          // Text('그 달에 기록할 수 있었던 날 중 기록한 날의 비율: 70% 이상 많음, 40% 이상 보통',
          //     style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─────────────────────────── 공통 소품 ───────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _StatCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1, style: Theme.of(context).textTheme.bodyMedium),
                    Text(r.$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
