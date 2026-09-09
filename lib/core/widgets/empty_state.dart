import 'package:flutter/material.dart';
import 'package:restree/core/theme/app_colors.dart';

/// 빈 상태(기록 없는 신규 유저) — 설계서 v1.3 §3.2.
/// 데이터에 따라 나무를 동적으로 그리지 않고, 고정된 기본 일러스트를 노출한다.
///
/// 적용 범위: 나의 나무 / 감정 정원 (주·월·연 공통), 기록 아카이브.
class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState({super.key, this.message = '아직 기록이 없어요.\n오늘의 하루를 남겨볼까요?'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: assets/images/empty_tree.png 등 고정 기본 이미지로 교체
            const Icon(Icons.spa_outlined, size: 96, color: AppColors.leafEmpty),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
