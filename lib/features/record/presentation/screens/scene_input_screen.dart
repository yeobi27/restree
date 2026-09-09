import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restree/core/constants/app_limits.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/photo_picker_strip.dart';
import 'package:restree/features/record/presentation/widgets/step_indicator.dart';

/// 04. "오늘 가장 기억에 남는 장면은 무엇인가요?"
///
/// 레이아웃 순서 (v1.3 §3.1 확정):
/// 질문 문구 → 사진 첨부 스트립 → 텍스트 입력 → 다음 버튼
class SceneInputScreen extends ConsumerStatefulWidget {
  const SceneInputScreen({super.key});

  @override
  ConsumerState<SceneInputScreen> createState() => _SceneInputScreenState();
}

class _SceneInputScreenState extends ConsumerState<SceneInputScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(recordDraftProvider).sceneText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(recordDraftProvider);
    final date = draft.editingDate != null ? DateTime.parse(draft.editingDate!) : DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
        title: Text(DateFormat('M월 d일 (E)', 'ko_KR').format(date)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text('오늘 가장 기억에 남는 장면은 무엇인가요?',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 20),

            // 사진 첨부 — 질문과 텍스트박스 사이 (v1.3 §3.1)
            PhotoPickerStrip(
              imageUrls: draft.imageUrls,
              onChanged: (urls) => ref.read(recordDraftProvider.notifier).setImages(urls),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: AppLimits.sceneTextMax,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: '자유롭게 적어보세요.',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text('${_controller.text.length}/${AppLimits.sceneTextMax}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const StepIndicator(currentStep: 1, totalSteps: 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(recordDraftProvider.notifier).setScene(_controller.text);
                  context.push('/record/gratitude');
                },
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
