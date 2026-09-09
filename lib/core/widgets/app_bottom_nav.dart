import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restree/core/theme/app_colors.dart';

/// 하단 내비게이션 — v1.2 §10 확정 구조.
///
/// 5슬롯: 홈 / 나의 나무 / ＋(오늘의 일기) / 감정 정원 / 기록(아카이브)
/// 단, ＋는 실제 탭(branch)이 아니라 기록 작성 플로우로 push하는 버튼이므로
/// StatefulShellRoute의 branch는 4개다.
class AppBottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppBottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 2,
          onPressed: () => context.push('/record/emotion'),
          child: const Icon(Icons.edit_note, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selected: navigationShell.currentIndex == 0,
              onTap: () => _go(0),
            ),
            _NavItem(
              icon: Icons.park_outlined,
              selected: navigationShell.currentIndex == 1,
              onTap: () => _go(1),
            ),
            const SizedBox(width: 64), // FAB 자리
            _NavItem(
              icon: Icons.sentiment_satisfied_outlined,
              selected: navigationShell.currentIndex == 2,
              onTap: () => _go(2),
            ),
            _NavItem(
              icon: Icons.article_outlined,
              selected: navigationShell.currentIndex == 3,
              onTap: () => _go(3),
            ),
          ],
        ),
      ),
    );
  }

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 27,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
