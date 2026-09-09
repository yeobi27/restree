import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';
import 'package:restree/features/record/presentation/providers/record_providers.dart';

/// 06~07. 하루 닫기 — 신규 작성 플로우에서만 진입한다.
/// (수정 플로우는 v1.5 §4에 따라 이 화면을 거치지 않는다)
///
/// TODO: 암전 → 나뭇잎 생성 연출은 Rive 애니메이션으로 교체 예정.
class CloseDayScreen extends ConsumerStatefulWidget {
  const CloseDayScreen({super.key});

  @override
  ConsumerState<CloseDayScreen> createState() => _CloseDayScreenState();
}

class _CloseDayScreenState extends ConsumerState<CloseDayScreen> {
  bool _closed = false;
  bool _saving = false;

  Future<void> _closeDay() async {
    setState(() => _saving = true);

    await ref.read(recordDraftProvider.notifier).commit(ref.read(recordRepositoryProvider));
    // treeState(연속 기록 등)는 서버 트리거가 재계산하므로 캐시만 무효화한다.
    ref.invalidate(treeStateProvider);

    if (!mounted) return;
    setState(() {
      _saving = false;
      _closed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nightBackground,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _closed ? _buildClosed(context) : _buildConfirm(context),
        ),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context) {
    return Padding(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const Text(
            '오늘 하루를\n여기서 내려놓을까요?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
          ),
          const Spacer(),
          // TODO: 나무 일러스트 + 원형 링 애니메이션 (Rive)
          const Icon(Icons.park, size: 160, color: AppColors.nightAccent),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight),
              onPressed: _saving ? null : _closeDay,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('오늘 하루 닫기'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            // v1.3 §3.3 — 03단계로 복귀하되 RecordDraft는 초기화하지 않는다.
            onPressed: () => context.go('/record/emotion'),
            child: const Text('아직 수정할게 있어요', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildClosed(BuildContext context) {
    return Padding(
      key: const ValueKey('closed'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const Text(
            '오늘도 잘 기록했어요.\n이제 편히 쉬어도 괜찮아요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
          ),
          const Spacer(),
          const Icon(Icons.park, size: 160, color: AppColors.nightAccent),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight),
              onPressed: () {
                ref.read(recordDraftProvider.notifier).reset();
                context.go('/home');
              },
              child: const Text('홈으로 돌아가기'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
