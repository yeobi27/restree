import 'package:flutter/material.dart';
import 'package:restree/core/theme/app_colors.dart';

/// 작성 플로우 하단 진행 표시 점 — 목업 기준 3단계(감정 → 장면 → 감사/한마디)
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({super.key, required this.currentStep, this.totalSteps = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final active = i == currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : AppColors.divider,
          ),
        );
      }),
    );
  }
}
