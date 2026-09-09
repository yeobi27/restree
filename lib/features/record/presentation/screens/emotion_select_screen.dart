import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/step_indicator.dart';

/// 03. "오늘의 감정은 어땠나요?"
///
/// v1.2 §9 — 감정 아이콘 하단의 텍스트 라벨(좋음/편안함/…)은 표시하지 않는다.
/// 다만 스크린 리더용 Semantics label은 유지한다.
class EmotionSelectScreen extends ConsumerWidget {
  const EmotionSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(recordDraftProvider);
    final date = draft.editingDate != null
        ? DateTime.parse(draft.editingDate!)
        : DateTime.now();
    final dateLabel = DateFormat('M월 d일 (E)', 'ko_KR').format(date);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(dateLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(recordDraftProvider.notifier).reset();
              context.go('/home');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 3),
            Text('오늘의 감정은 어땠나요?', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: Emotion.values.map((e) {
                return _EmotionIcon(
                  emotion: e,
                  selected: draft.emotion == e,
                  onTap: () => ref.read(recordDraftProvider.notifier).setEmotion(e),
                );
              }).toList(),
            ),
            const Spacer(flex: 4),
            const StepIndicator(currentStep: 0, totalSteps: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: draft.emotion == null ? null : () => context.push('/record/scene'),
                child: const Text('다음'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EmotionIcon extends StatelessWidget {
  final Emotion emotion;
  final bool selected;
  final VoidCallback onTap;

  const _EmotionIcon({required this.emotion, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 라벨은 화면에 그리지 않되 Semantics로만 노출 (v1.2 §9 접근성 메모)
    return Semantics(
      label: emotion.label,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: emotion.color.withValues(alpha: selected ? 1.0 : 0.45),
          ),
          // TODO: 목업의 표정 아이콘 에셋으로 교체
          child: Icon(
            switch (emotion) {
              Emotion.good || Emotion.comfortable => Icons.sentiment_satisfied,
              Emotion.normal => Icons.sentiment_neutral,
              Emotion.tired => Icons.sentiment_dissatisfied,
              Emotion.hard => Icons.sentiment_very_dissatisfied,
            },
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
