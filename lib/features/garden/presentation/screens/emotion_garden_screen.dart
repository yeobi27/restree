import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/core/widgets/empty_state.dart';
import 'package:restree/features/garden/presentation/widgets/emotion_bar_list.dart';
import 'package:restree/features/garden/presentation/widgets/emotion_plant_chart.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/record_preview_card.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/presentation/widgets/month_calendar_sheet.dart';

/// 10. 감정 정원 — 주간 / 월간 / 연간
///
/// v1.4 §3.1 — 우측 상단 톱니바퀴(설정) 제거, 햄버거 메뉴로 일원화.
/// v1.5 §5.2 — 이 화면의 "이번 주/달/해는~" 문구가 AI 생성(aiSummary)을 쓰는
/// 유일한 지점이다. (홈 화면은 고정 카피)
class EmotionGardenScreen extends StatelessWidget {
  const EmotionGardenScreen({super.key});

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
          title: const Text('감정 정원'),
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

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsPeriodicProvider((PeriodType.week, '2026-W35')));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        if (stats.isEmpty) return const EmptyState();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Text('8월 24일 - 8월 30일', style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            Center(child: Text('이번 주의 마음', style: Theme.of(context).textTheme.headlineSmall)),
            const SizedBox(height: 20),
            EmotionPlantChart(distribution: stats.emotionDistribution),
            const SizedBox(height: 24),
            _Card(
              title: '이번 주의 마음',
              child: EmotionBarList(distribution: stats.emotionDistribution),
            ),
            if (stats.aiSummary != null) ...[
              const SizedBox(height: 16),
              _Card(title: 'AI 한 줄 요약', child: Text(stats.aiSummary!)),
            ],
            if (stats.highlightRecordIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              _HighlightSection(
                title: '이번 주의 한 장면',
                recordIds: stats.highlightRecordIds,
              ),
            ],
          ],
        );
      },
    );
  }
}

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
        final dominant = stats.dominantEmotion;
        final dominantCount = dominant == null ? null : stats.emotionDistribution[dominant];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left, color: AppColors.primary)),
                Text('${month.year}년 ${month.month}월',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            // 지시사항 ① — 감정 비율에 따른 식물(높이) 그래프
            EmotionPlantChart(distribution: stats.emotionDistribution),
            const SizedBox(height: 24),
            _Card(
              title: '${month.month}월의 감정',
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('가장 많았던 감정', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          if (dominant != null && dominantCount != null)
                            Row(
                              children: [
                                CircleAvatar(radius: 18, backgroundColor: dominant.color),
                                const SizedBox(width: 8),
                                Text('${dominantCount.count}일',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                                const SizedBox(width: 4),
                                Text('(${(dominantCount.percentage * 100).round()}%)',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('이번 달은', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          // v1.5 §5.2 — AI 생성 요약이 들어가는 자리
                          Text(stats.aiSummary ?? '',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _NavCard(
              label: '감정 날짜 보기',
              // 감정 정원은 그날의 감정 색으로 칠하는 히트맵 모드
              onTap: () => showMonthCalendarSheet(context,
                  month: month, mode: CalendarColorMode.garden),
            ),
          ],
        );
      },
    );
  }
}

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
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Text('2026년의 감정 정원', style: Theme.of(context).textTheme.headlineSmall)),
            const SizedBox(height: 6),
            Center(
              child: Text('올해 당신의 마음은 어떤 계절을 지나왔나요?',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 20),
            _MonthGrid(months: stats.monthlyBreakdown),

            // NOTE: "감정의 계절"(겨울/봄/여름/가을) 섹션은 v1.2 §7에서 구현 제외로 확정.
            // 필요 시 monthlyBreakdown을 3개월 단위로 묶어 스키마 변경 없이 되살릴 수 있다.

            const SizedBox(height: 24),
            _Card(
              title: '2026년의 마음 요약',
              child: EmotionBarList(distribution: stats.emotionDistribution),
            ),
            if (stats.highlightRecordIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              _HighlightSection(
                title: '올해의 한 장면 BEST 3',
                recordIds: stats.highlightRecordIds,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 연간 탭 12개월 그리드 — 각 달의 대표 감정으로 식물/이모지를 표시
class _MonthGrid extends StatelessWidget {
  final List<MonthlySummary> months;

  const _MonthGrid({required this.months});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: months.map((m) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${m.month}월', style: Theme.of(context).textTheme.bodySmall),
                  if (m.dominantEmotion != null)
                    CircleAvatar(radius: 8, backgroundColor: m.dominantEmotion!.color),
                ],
              ),
              const Spacer(),
              // TODO: 달마다 다른 식물 일러스트 에셋으로 교체
              const Center(
                  child: Icon(Icons.grass, color: AppColors.primaryLight, size: 34)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HighlightSection extends ConsumerWidget {
  final String title;
  final List<String> recordIds;

  const _HighlightSection({required this.title, required this.recordIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      title: title,
      child: Column(
        children: recordIds.map((id) {
          final async = ref.watch(recordByDateProvider(id));
          return async.maybeWhen(
            data: (record) => record == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RecordPreviewCard(record: record),
                  ),
            orElse: () => const SizedBox.shrink(),
          );
        }).toList(),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          child,
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavCard({required this.label, required this.onTap});

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
              const Icon(Icons.sentiment_satisfied_outlined, color: AppColors.primary),
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
