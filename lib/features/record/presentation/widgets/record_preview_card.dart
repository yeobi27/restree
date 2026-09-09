import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';

/// 기록 미리보기 카드 — 홈 "오늘의 기록", 캘린더 바텀시트 선택 결과,
/// 아카이브 리스트에서 공통으로 쓰인다. 탭하면 항상 동일한 상세보기로 이동.
class RecordPreviewCard extends StatelessWidget {
  final DailyRecord record;
  final bool showBackground;

  const RecordPreviewCard({super.key, required this.record, this.showBackground = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/record/detail/${record.date}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: showBackground ? AppColors.surfaceMuted : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: record.emotion.color,
              child: Icon(
                switch (record.emotion) {
                  Emotion.good || Emotion.comfortable => Icons.sentiment_satisfied,
                  Emotion.normal => Icons.sentiment_neutral,
                  Emotion.tired => Icons.sentiment_dissatisfied,
                  Emotion.hard => Icons.sentiment_very_dissatisfied,
                },
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('M월 d일 (E)', 'ko_KR').format(DateTime.parse(record.date)),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.sceneText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (record.hasPhoto) ...[
              const SizedBox(width: 12),
              _Thumbnail(extraCount: record.imageUrls.length - 1),
            ],
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final int extraCount;

  const _Thumbnail({required this.extraCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(10),
          ),
          // TODO: cached_network_image로 record.thumbnailUrl 렌더링
          child: const Icon(Icons.photo, size: 20, color: AppColors.textSecondary),
        ),
        if (extraCount > 0)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('+$extraCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
      ],
    );
  }
}
