import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/record_preview_card.dart';

/// 캘린더 색칠 방식 — 두 화면이 같은 캘린더를 쓰지만 정보 밀도가 다르다.
/// - tree: 기록 유무만 표시(전부 균일한 초록) — "나의 나무 › 기록 날짜 보기"
/// - garden: 그날의 감정 색으로 표시(히트맵) — "감정 정원 › 감정 날짜 보기" (v1.2 §8.2)
enum CalendarColorMode { tree, garden }

/// 월간 탭 하단 버튼을 누르면 올라오는 캘린더 바텀시트.
void showMonthCalendarSheet(
  BuildContext context, {
  required DateTime month,
  required CalendarColorMode mode,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MonthCalendarSheet(month: month, mode: mode),
  );
}

class _MonthCalendarSheet extends ConsumerStatefulWidget {
  final DateTime month;
  final CalendarColorMode mode;

  const _MonthCalendarSheet({required this.month, required this.mode});

  @override
  ConsumerState<_MonthCalendarSheet> createState() => _MonthCalendarSheetState();
}

class _MonthCalendarSheetState extends ConsumerState<_MonthCalendarSheet> {
  String? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(widget.month.year, widget.month.month, 1);
    final last = DateTime(widget.month.year, widget.month.month + 1, 0);
    final recordsAsync = ref.watch(recordsInRangeProvider((first, last)));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${widget.month.year}년 ${widget.month.month}월',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: AppColors.primary)),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (records) {
                final byDate = {for (final r in records) r.date: r};
                final selected = _selectedDate == null ? null : byDate[_selectedDate];

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const _WeekdayHeader(),
                    const SizedBox(height: 8),
                    _DayGrid(
                      first: first,
                      last: last,
                      byDate: byDate,
                      mode: widget.mode,
                      selectedDate: _selectedDate,
                      onSelect: (d) => setState(() => _selectedDate = d),
                    ),
                    const SizedBox(height: 24),
                    if (selected != null) RecordPreviewCard(record: selected),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _labels
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Center(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: e.key == 0 ? Colors.redAccent : AppColors.textSecondary,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _DayGrid extends StatelessWidget {
  final DateTime first;
  final DateTime last;
  final Map<String, DailyRecord> byDate;
  final CalendarColorMode mode;
  final String? selectedDate;
  final ValueChanged<String> onSelect;

  const _DayGrid({
    required this.first,
    required this.last,
    required this.byDate,
    required this.mode,
    required this.selectedDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final leadingBlanks = first.weekday % 7; // 일요일 시작 기준
    final cells = <Widget>[
      ...List.generate(leadingBlanks, (_) => const SizedBox.shrink()),
      ...List.generate(last.day, (i) {
        final day = i + 1;
        final dateKey =
            '${first.year.toString().padLeft(4, '0')}-${first.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final record = byDate[dateKey];
        final isSelected = selectedDate == dateKey;

        Color? fill;
        if (record != null) {
          fill = mode == CalendarColorMode.garden
              ? record.emotion.color
              : AppColors.leafFilled;
        }

        return GestureDetector(
          onTap: record == null ? null : () => onSelect(dateKey),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  color: record != null ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}
