// 최종 수정: 2026-10-22
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/constants/layout.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/core/utils/kst.dart';
import 'package:restree/core/utils/periods.dart';
import 'package:restree/core/widgets/empty_state.dart';
import 'package:restree/features/auth/presentation/providers/auth_providers.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/record_preview_card.dart';

/// 11. 나의 기록(기록 아카이브)
///
/// 필터 구성은 기존 "전체/기분/감사/나에게 한마디"(레코드마다 항상 존재하는
/// 필드라 사실상 필터 역할을 못 함)에서 기간별/감정별/사진만으로 교체되었다.
/// 우측 상단 북마크는 즐겨찾기 목록 진입점 (v1.4 §6).
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  Emotion? _emotionFilter;
  bool _photoOnly = false;
  String _query = '';
  _ArchivePeriod _period = _ArchivePeriod.all;

  /// 기간 메뉴에서 보고 있는 연도. 메뉴를 열 때 선택된 기간의 해(없으면 올해)로 맞춘다.
  int _menuYear = DateTime.now().year;

  static const _menuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(AppColors.surface),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final today = viewToday();
    final accountStart = ref.watch(accountStartDateProvider);

    // 계정을 만든 날부터 오늘까지의 기록을 한 번만 불러오고, 기간·감정·사진·검색은 모두 앱에서 거른다.
    // 기간을 바꿔도 서버 요청이나 로딩이 없다(일기는 하루 1건이라 몇 년치도 부담이 적다).
    // 주의: provider key(DateTime)에는 날짜만 쓴다 — 시각이 섞이면 build마다 다시 불러온다.
    final recordsAsync = ref.watch(recordsInRangeProvider(
        (accountStart ?? DateTime(today.year - 1, today.month, 1), today)));
    final allRecords = recordsAsync.valueOrNull ?? const <DailyRecord>[];

    // 달별 기록 수(기간 메뉴에 표시)와 가장 이른 연도
    final countByMonth = <(int, int), int>{};
    var firstYear = accountStart?.year ?? today.year;
    for (final r in allRecords) {
      final y = int.parse(r.date.substring(0, 4));
      final m = int.parse(r.date.substring(5, 7));
      countByMonth[(y, m)] = (countByMonth[(y, m)] ?? 0) + 1;
      if (y < firstYear) firstYear = y;
    }

    final startKey = _period.isAll ? null : formatDateKey(_period.start!);
    final endKey = _period.isAll ? null : formatDateKey(_period.end!);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.push('/menu'),
        ),
        title: const Text('나의 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: '즐겨찾기',
            onPressed: () => context.push('/archive/favorites'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '기록을 검색해보세요',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _periodMenu(today, firstYear, countByMonth),
                const SizedBox(width: 8),
                _emotionMenu(),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.image_outlined,
                  label: '사진만',
                  selected: _photoOnly,
                  onTap: () => setState(() => _photoOnly = !_photoOnly),
                ),
              ],
            ),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (records) {
                final filtered = records.where((r) {
                  if (startKey != null &&
                      (r.date.compareTo(startKey) < 0 || r.date.compareTo(endKey!) > 0)) {
                    return false;
                  }
                  if (_emotionFilter != null && r.emotion != _emotionFilter) return false;
                  if (_photoOnly && !r.hasPhoto) return false;
                  if (_query.isNotEmpty) {
                    final haystack =
                        '${r.sceneText}${r.gratitudeText}${r.messageToSelf}${r.keywords.join()}';
                    if (!haystack.contains(_query)) return false;
                  }
                  return true;
                }).toList()
                  ..sort((a, b) => b.date.compareTo(a.date)); // 최신순

                if (filtered.isEmpty) {
                  return const EmptyState(message: '조건에 맞는 기록이 없어요.');
                }
                return _GroupedRecordList(records: filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 기간 드롭다운 — 프리셋 + 연도 ‹ › + 그 해의 기록 있는 달.
  /// 한 번에 한 해만 보여서 몇 년이 지나도 메뉴가 길어지지 않는다(최대 프리셋 3 + 연 전체 1 + 12개월).
  Widget _periodMenu(DateTime today, int firstYear, Map<(int, int), int> countByMonth) {
    final presets = [
      _ArchivePeriod.all,
      _ArchivePeriod('이번 달', start: DateTime(today.year, today.month, 1), end: today),
      _ArchivePeriod('최근 3개월', start: DateTime(today.year, today.month - 2, 1), end: today),
    ];
    final months = [
      for (var m = 12; m >= 1; m--)
        if ((countByMonth[(_menuYear, m)] ?? 0) > 0) m,
    ];
    final yearTotal = months.fold<int>(0, (sum, m) => sum + countByMonth[(_menuYear, m)]!);

    return MenuAnchor(
      style: _menuStyle,
      builder: (context, controller, _) => _Chip(
        icon: Icons.calendar_today_outlined,
        label: _period.isAll ? '기간별' : _period.label,
        selected: !_period.isAll,
        onTap: () {
          if (controller.isOpen) {
            controller.close();
            return;
          }
          setState(() => _menuYear = _period.year ?? today.year);
          controller.open();
        },
      ),
      menuChildren: [
        for (final p in presets)
          _menuItem(p.label,
              selected: _period.year == null && _period.label == p.label,
              onPressed: () => setState(() => _period = p)),
        const Divider(height: 8),
        // 연도 이동 버튼은 메뉴 항목이 아니라서 눌러도 메뉴가 닫히지 않는다.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _menuYear > firstYear ? () => setState(() => _menuYear--) : null,
              color: AppColors.primary,
              disabledColor: AppColors.divider,
              icon: const Icon(Icons.chevron_left),
            ),
            SizedBox(
              width: 112,
              child: Text('$_menuYear년',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              onPressed: _menuYear < today.year ? () => setState(() => _menuYear++) : null,
              color: AppColors.primary,
              disabledColor: AppColors.divider,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (months.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text('이 해에는 기록이 없어요', style: TextStyle(color: AppColors.textSecondary)),
          )
        else ...[
          _menuItem('$_menuYear년 전체',
              count: yearTotal,
              selected: _period.year == _menuYear && _period.month == null,
              onPressed: () => setState(() => _period = _ArchivePeriod.year(_menuYear, today))),
          for (final m in months)
            _menuItem('$m월',
                count: countByMonth[(_menuYear, m)],
                selected: _period.year == _menuYear && _period.month == m,
                onPressed: () => setState(() => _period = _ArchivePeriod.month(_menuYear, m, today))),
        ],
      ],
    );
  }

  /// 감정 드롭다운 — 항목마다 직접 콜백을 걸어서 "전체(null)"도 문제없이 선택된다.
  Widget _emotionMenu() {
    return MenuAnchor(
      style: _menuStyle,
      builder: (context, controller, _) => _Chip(
        icon: Icons.sentiment_satisfied_outlined,
        label: _emotionFilter?.label ?? '감정별',
        selected: _emotionFilter != null,
        onTap: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
      ),
      menuChildren: [
        _menuItem('전체',
            selected: _emotionFilter == null, onPressed: () => setState(() => _emotionFilter = null)),
        for (final e in Emotion.values)
          _menuItem(e.label,
              selected: _emotionFilter == e, onPressed: () => setState(() => _emotionFilter = e)),
      ],
    );
  }

  Widget _menuItem(String label,
      {int? count, required bool selected, required VoidCallback onPressed}) {
    return MenuItemButton(
      onPressed: onPressed,
      trailingIcon: selected
          ? const Icon(Icons.check, size: 18, color: AppColors.primary)
          : const SizedBox(width: 18),
      child: SizedBox(
        width: 140,
        child: Row(
          children: [
            Expanded(child: Text(label)),
            if (count != null)
              Text('$count', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// 월별로 섹션을 나눠 렌더링 — 리스트가 길어져도 현재 위치를 알 수 있게 한다.
class _GroupedRecordList extends StatelessWidget {
  final List<DailyRecord> records;

  const _GroupedRecordList({required this.records});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<DailyRecord>>{};
    for (final r in records) {
      final ym = r.date.substring(0, 7); // yyyy-MM
      groups.putIfAbsent(ym, () => []).add(r);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      slivers: [
        for (final ym in keys) ...[
          SliverStickyHeader(label: _formatYm(ym), count: groups[ym]!.length),
          SliverList.separated(
            itemCount: groups[ym]!.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: RecordPreviewCard(record: groups[ym]![i], showBackground: false),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: kFabClearance)),
      ],
    );
  }

  static String _formatYm(String ym) {
    final parts = ym.split('-');
    return '${parts[0]}년 ${int.parse(parts[1])}월';
  }
}

/// 월 구분 헤더 — 스크롤 시 상단에 고정된다.
class SliverStickyHeader extends StatelessWidget {
  final String label;
  final int count;

  const SliverStickyHeader({super.key, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(label: label, count: count),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final int count;

  _HeaderDelegate({required this.label, required this.count});

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.eco, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(width: 8),
          Text('총 $count개의 기록', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      old.label != label || old.count != count;
}

/// 기록 아카이브의 기간 필터. 시작·끝은 날짜만 담는다.
class _ArchivePeriod {
  const _ArchivePeriod(this.label, {this.start, this.end, this.year, this.month});

  /// 특정 달 — 진행 중인 달이면 끝을 오늘로 자른다.
  factory _ArchivePeriod.month(int year, int month, DateTime today) {
    final r = monthRangeOf(DateTime(year, month, 1));
    return _ArchivePeriod('$year년 $month월',
        start: r.start, end: r.end.isAfter(today) ? today : r.end, year: year, month: month);
  }

  /// 한 해 전체 — 올해면 끝을 오늘로 자른다.
  factory _ArchivePeriod.year(int year, DateTime today) {
    final end = DateTime(year, 12, 31);
    return _ArchivePeriod('$year년',
        start: DateTime(year, 1, 1), end: end.isAfter(today) ? today : end, year: year);
  }

  /// 전체 기간 — 계정을 만든 날부터 오늘까지
  static const all = _ArchivePeriod('전체 기간');

  final String label;
  final DateTime? start;
  final DateTime? end;

  /// 메뉴에서 연도·달로 골랐을 때만 값이 있다(선택 표시용).
  final int? year;
  final int? month;

  bool get isAll => start == null;
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _Chip({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0DF) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }
}

