import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/record_preview_card.dart';

/// 08. 홈 — 오늘 작성 여부에 따라 문구와 하단 카드가 달라진다.
///
/// v1.5 §5.2 — 홈의 안내 문구는 AI 생성이 아니라 고정 카피다.
/// (AI 생성 요약은 감정 정원 화면에서만 사용)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _copyBeforeWriting = '오늘도 고생했어요\n하루를 마무리해 볼까요?';
  static const _copyAfterWriting = '당신의 작은 기록이\n나무를 키우고 마음을 피워요.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayKey =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    final treeState = ref.watch(treeStateProvider);
    final todayRecord = ref.watch(recordByDateProvider(todayKey));
    final yesterdayRecord = ref.watch(recordByDateProvider(yesterdayKey));

    final hasToday = todayRecord.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.push('/menu'),
        ),
        title: const Text(
          'RESTREE',
          style: TextStyle(
            color: AppColors.brandGold,
            fontSize: 20,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            // TODO: 알림 센터 화면 미정
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Text(
              DateFormat('M월 d일 (E)', 'ko_KR').format(now),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              hasToday ? _copyAfterWriting : _copyBeforeWriting,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),

          // TODO: treeState.level 단계별 나무 일러스트 에셋 연결
          const Icon(Icons.park, size: 180, color: AppColors.leafFilled),
          const SizedBox(height: 24),

          treeState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('오류: $e'),
            data: (state) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE8F0DF),
                    child: Icon(Icons.eco, size: 17, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('연속 기록', style: TextStyle(fontSize: 15))),
                  Text('${state.currentStreak}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Text('일', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.eco, size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(
                hasToday ? '오늘의 기록' : '어제의 나에게서 온 기록',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 작성 후에는 오늘 기록을, 작성 전에는 어제 기록을 보여준다.
          (hasToday ? todayRecord : yesterdayRecord).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('오류: $e'),
            data: (record) => record == null
                ? const _NoRecordHint()
                : RecordPreviewCard(record: record),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _NoRecordHint extends StatelessWidget {
  const _NoRecordHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text('아직 기록이 없어요.',
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
