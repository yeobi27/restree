import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/core/widgets/empty_state.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/presentation/widgets/month_calendar_sheet.dart';
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
        body: const TabBarView(
          children: [_WeeklyTab(), _MonthlyTab(), _YearlyTab()],
        ),
      ),
    );
  }
}

// ─────────────────────────── 주간 ───────────────────────────

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 현재 주 계산 + 좌우 화살표로 주 이동 (지금은 목업 기준 주 고정)
    final weekStart = DateTime(2026, 8, 24);
    final weekEnd = DateTime(2026, 8, 30);
    final statsAsync = ref.watch(statsPeriodicProvider((PeriodType.week, '2026-W35')));
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
            padding: const EdgeInsets.all(20),
            children: [
              const _PeriodHeader(label: '8월 24일 - 8월 30일'),
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
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = DateTime(2026, 8);
    final statsAsync = ref.watch(statsPeriodicProvider((PeriodType.month, '2026-08')));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        if (stats.isEmpty) return const EmptyState();
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PeriodHeader(label: '${month.year}년 ${month.month}월', withArrows: true),
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
  const _YearlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsPeriodicProvider((PeriodType.year, '2026')));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        if (stats.isEmpty) return const EmptyState();
        final busiest = stats.busiestMonth;
        final elapsed = DateTime.now().difference(stats.periodStart).inDays + 1;
        final percent = ((stats.daysRecorded / elapsed) * 100).clamp(0, 100).round();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _PeriodHeader(label: '2026년', withArrows: true),
            const SizedBox(height: 20),
            Center(child: Text('2026년의 나무', style: Theme.of(context).textTheme.headlineSmall)),
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
            _MonthlyBreakdownCard(months: stats.monthlyBreakdown),
          ],
        );
      },
    );
  }
}

/// 연간 탭 "월별 기록 현황" — monthlyBreakdown[].density 로 잎 크기를 달리한다.
class _MonthlyBreakdownCard extends StatelessWidget {
  final List<MonthlySummary> months;

  const _MonthlyBreakdownCard({required this.months});

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
          Text('월별 기록 현황', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          // TODO: 목업은 나무를 중심으로 12개월이 원형 배치 — 지금은 단순 그리드로 대체
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: months.map((m) {
              final size = switch (m.density) {
                MonthDensity.high => 28.0,
                MonthDensity.medium => 22.0,
                MonthDensity.low => 16.0,
              };
              return SizedBox(
                width: 56,
                child: Column(
                  children: [
                    Icon(Icons.eco, size: size, color: AppColors.leafFilled),
                    const SizedBox(height: 4),
                    Text('${m.month}월', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: MonthDensity.values
                .map((d) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(children: [
                        Icon(Icons.eco,
                            size: switch (d) {
                              MonthDensity.high => 18.0,
                              MonthDensity.medium => 14.0,
                              MonthDensity.low => 11.0,
                            },
                            color: AppColors.leafFilled),
                        const SizedBox(width: 4),
                        Text(d.label, style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── 공통 소품 ───────────────────────────

class _PeriodHeader extends StatelessWidget {
  final String label;
  final bool withArrows;

  const _PeriodHeader({required this.label, this.withArrows = false});

  @override
  Widget build(BuildContext context) {
    if (!withArrows) {
      return Center(child: Text(label, style: Theme.of(context).textTheme.bodyMedium));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // TODO: 이전/다음 기간 이동 로직 연결
        IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right, color: AppColors.primary)),
      ],
    );
  }
}

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
