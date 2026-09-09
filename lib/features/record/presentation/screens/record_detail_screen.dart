import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';

enum _KebabAction { edit, delete, share, favorite }

/// 일기 상세보기 — 홈/나의 나무/감정 정원/아카이브 어디서 들어와도 동일한 화면.
///
/// 우측 상단 케밥 메뉴(⋮) 구성은 v1.4 §3.2에서 확정: 수정 / 삭제 / 공유 / 즐겨찾기.
/// TODO: 상점에서 구매한 꾸미기(폰트/배경/이펙트)가 적용되는 유일한 화면(v1.3 §4.4).
class RecordDetailScreen extends ConsumerWidget {
  final String date;

  const RecordDetailScreen({super.key, required this.date});

  Future<void> _onAction(BuildContext context, WidgetRef ref, _KebabAction action, DailyRecord record) async {
    final repo = ref.read(recordRepositoryProvider);

    switch (action) {
      case _KebabAction.edit:
        // v1.5 §4 — 03~05단계를 프리필한 채 재사용, 06~07은 스킵된다.
        ref.read(recordDraftProvider.notifier).loadForEdit(record);
        if (context.mounted) context.push('/record/emotion');

      case _KebabAction.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('기록을 삭제할까요?'),
            content: const Text('삭제한 기록은 일정 기간 후 완전히 삭제됩니다.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
            ],
          ),
        );
        if (ok == true) {
          // v1.5 §3 — 하드 삭제가 아니라 deletedAt만 기록하는 소프트 삭제
          await repo.softDeleteRecord(date);
          ref.invalidate(recordByDateProvider(date));
          ref.invalidate(treeStateProvider);
          if (context.mounted) context.go('/archive');
        }

      case _KebabAction.share:
        // TODO: 공유 포맷(카드형 이미지 vs 텍스트) 미정 — v1.4 §7.3
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유 기능은 준비 중입니다.')),
        );

      case _KebabAction.favorite:
        await repo.toggleFavorite(date, !record.isFavorite);
        ref.invalidate(recordByDateProvider(date));
        ref.invalidate(favoriteRecordsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(recordByDateProvider(date));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
        title: Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(DateTime.parse(date))),
        actions: [
          recordAsync.maybeWhen(
            data: (record) => record == null
                ? const SizedBox.shrink()
                : PopupMenuButton<_KebabAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (a) => _onAction(context, ref, a, record),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: _KebabAction.edit, child: Text('수정')),
                      const PopupMenuItem(value: _KebabAction.delete, child: Text('삭제')),
                      const PopupMenuItem(value: _KebabAction.share, child: Text('공유')),
                      PopupMenuItem(
                        value: _KebabAction.favorite,
                        child: Text(record.isFavorite ? '즐겨찾기 해제' : '즐겨찾기'),
                      ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (record) {
          if (record == null) {
            return const Center(child: Text('기록을 찾을 수 없어요.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Section(
                title: '오늘의 감정',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: Emotion.values.map((e) {
                    final selected = e == record.emotion;
                    return CircleAvatar(
                      radius: 26,
                      backgroundColor: e.color.withValues(alpha: selected ? 1.0 : 0.2),
                      child: Icon(
                        switch (e) {
                          Emotion.good || Emotion.comfortable => Icons.sentiment_satisfied,
                          Emotion.normal => Icons.sentiment_neutral,
                          Emotion.tired => Icons.sentiment_dissatisfied,
                          Emotion.hard => Icons.sentiment_very_dissatisfied,
                        },
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: '오늘 가장 기억에 남는 장면',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.hasPhoto) ...[
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: record.imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // TODO: cached_network_image로 교체
                            child: const Icon(Icons.photo, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(record.sceneText, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: '오늘 고마웠던 것',
                child: Text(record.gratitudeText, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 16),
              _Section(
                title: '오늘의 나에게 한마디',
                child: Text(record.messageToSelf, style: Theme.of(context).textTheme.bodyMedium),
              ),
              if (record.keywords.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(
                  title: '그날의 키워드',
                  // v1.3 §3.4 — AI 추출 키워드는 읽기 전용. 편집·삭제 UI를 제공하지 않는다.
                  child: Wrap(
                    spacing: 8,
                    children: record.keywords
                        .map((k) => Chip(
                              label: Text(k),
                              backgroundColor: AppColors.surfaceMuted,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
