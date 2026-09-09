import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restree/core/constants/app_limits.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';
import 'package:restree/features/record/presentation/widgets/step_indicator.dart';

/// 05. "오늘 고마웠던 것은?" + "오늘의 나에게 한마디"
///
/// v1.5 §4 — 하단 버튼이 모드에 따라 달라진다.
/// - 신규 작성: "다음" → 06단계(하루 닫기)로 진행
/// - 수정: "저장" → 즉시 저장 후 상세보기로 복귀 (06~07 스킵)
class GratitudeInputScreen extends ConsumerStatefulWidget {
  const GratitudeInputScreen({super.key});

  @override
  ConsumerState<GratitudeInputScreen> createState() => _GratitudeInputScreenState();
}

class _GratitudeInputScreenState extends ConsumerState<GratitudeInputScreen> {
  late final TextEditingController _gratitudeController;
  late final TextEditingController _messageController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(recordDraftProvider);
    _gratitudeController = TextEditingController(text: draft.gratitudeText);
    _messageController = TextEditingController(text: draft.messageToSelf);
  }

  @override
  void dispose() {
    _gratitudeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    ref.read(recordDraftProvider.notifier)
      ..setGratitude(_gratitudeController.text)
      ..setMessageToSelf(_messageController.text);
  }

  Future<void> _saveAndReturn() async {
    setState(() => _saving = true);
    _syncDraft();

    final editingDate = ref.read(recordDraftProvider).editingDate!;
    await ref.read(recordDraftProvider.notifier).commit(ref.read(recordRepositoryProvider));

    // 수정 반영을 화면에 즉시 보이도록 캐시 무효화
    ref.invalidate(recordByDateProvider(editingDate));
    ref.invalidate(treeStateProvider);

    if (!mounted) return;
    ref.read(recordDraftProvider.notifier).reset();
    context.go('/record/detail/$editingDate');
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _LabeledField(
                    label: '오늘 고마웠던 것은?',
                    controller: _gratitudeController,
                    maxLength: AppLimits.gratitudeTextMax,
                    minLines: 5,
                  ),
                  const SizedBox(height: 28),
                  _LabeledField(
                    label: '오늘의 나에게 한마디',
                    controller: _messageController,
                    maxLength: AppLimits.messageToSelfMax,
                    minLines: 4,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                const StepIndicator(currentStep: 2, totalSteps: 3),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            if (draft.isEditing) {
                              _saveAndReturn();
                            } else {
                              _syncDraft();
                              context.push('/record/close');
                            }
                          },
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(draft.isEditing ? '저장' : '다음'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final int maxLength;
  final int minLines;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.maxLength,
    required this.minLines,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: widget.controller,
                maxLength: widget.maxLength,
                minLines: widget.minLines,
                maxLines: widget.minLines + 2,
                decoration: const InputDecoration(
                  hintText: '자유롭게 적어보세요.',
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              Text('${widget.controller.text.length}/${widget.maxLength}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
