import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/core/widgets/empty_state.dart';
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

  @override
  Widget build(BuildContext context) {
    // TODO: 기간별 필터 UI(월/연 선택) 연결 — 현재는 최근 1년 고정
    final now = DateTime.now();
    final recordsAsync =
        ref.watch(recordsInRangeProvider((DateTime(now.year - 1, now.month), now)));

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
          _FilterChips(
            emotionFilter: _emotionFilter,
            photoOnly: _photoOnly,
            onEmotionChanged: (e) => setState(() => _emotionFilter = e),
            onPhotoOnlyChanged: (v) => setState(() => _photoOnly = v),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (records) {
                final filtered = records.where((r) {
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
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

class _FilterChips extends StatelessWidget {
  final Emotion? emotionFilter;
  final bool photoOnly;
  final ValueChanged<Emotion?> onEmotionChanged;
  final ValueChanged<bool> onPhotoOnlyChanged;

  const _FilterChips({
    required this.emotionFilter,
    required this.photoOnly,
    required this.onEmotionChanged,
    required this.onPhotoOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // TODO: 기간별 선택 바텀시트 연결
          _Chip(
            icon: Icons.calendar_today_outlined,
            label: '기간별',
            selected: false,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          PopupMenuButton<Emotion?>(
            onSelected: onEmotionChanged,
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('전체')),
              ...Emotion.values.map((e) => PopupMenuItem(value: e, child: Text(e.label))),
            ],
            child: _Chip(
              icon: Icons.sentiment_satisfied_outlined,
              label: emotionFilter?.label ?? '감정별',
              selected: emotionFilter != null,
            ),
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.image_outlined,
            label: '사진만',
            selected: photoOnly,
            onTap: () => onPhotoOnlyChanged(!photoOnly),
          ),
        ],
      ),
    );
  }
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
