import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';

/// 01. 시작 화면 — 목업 기준 3장 스와이프 구성.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // TODO: 2·3페이지 문구는 목업에 없어 미정 — 확정 후 교체
  static const _pages = [
    '하루를 마무리하고\n내일로 넘어가기 전\n쉬어가는 시간',
    '오늘의 감정을 남기면\n나무가 한 뼘씩 자라요',
    '쌓인 기록이\n나만의 숲이 됩니다',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TODO: 로고 에셋(assets/images/logo.png)으로 교체
                    const Icon(Icons.eco, size: 110, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text('RESTREE',
                        style: TextStyle(
                          fontSize: 30,
                          letterSpacing: 6,
                          color: AppColors.brandGold,
                        )),
                    const SizedBox(height: 32),
                    Text(_pages[i],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? AppColors.primary : AppColors.divider,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('시작하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
