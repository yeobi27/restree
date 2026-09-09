import 'package:go_router/go_router.dart';
import 'package:restree/core/widgets/app_bottom_nav.dart';
import 'package:restree/features/archive/presentation/screens/archive_screen.dart';
import 'package:restree/features/archive/presentation/screens/favorites_screen.dart';
import 'package:restree/features/auth/presentation/screens/login_screen.dart';
import 'package:restree/features/garden/presentation/screens/emotion_garden_screen.dart';
import 'package:restree/features/home/presentation/screens/home_screen.dart';
import 'package:restree/features/menu/presentation/screens/menu_screen.dart';
import 'package:restree/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:restree/features/record/presentation/screens/close_day_screen.dart';
import 'package:restree/features/record/presentation/screens/emotion_select_screen.dart';
import 'package:restree/features/record/presentation/screens/gratitude_input_screen.dart';
import 'package:restree/features/record/presentation/screens/record_detail_screen.dart';
import 'package:restree/features/record/presentation/screens/scene_input_screen.dart';
import 'package:restree/features/shop/presentation/screens/shop_screen.dart';
import 'package:restree/features/tree/presentation/screens/my_tree_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // 햄버거 메뉴 — 하단 탭 셸 바깥의 독립 라우트로 push (v1.2 §10)
    GoRoute(path: '/menu', builder: (_, __) => const MenuScreen()),
    GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),

    // 기록 작성 플로우 (03~07). 수정 시에는 05단계에서 저장 후 바로 상세보기로
    // 이동하므로 /record/close를 거치지 않는다 (v1.5 §4).
    GoRoute(path: '/record/emotion', builder: (_, __) => const EmotionSelectScreen()),
    GoRoute(path: '/record/scene', builder: (_, __) => const SceneInputScreen()),
    GoRoute(path: '/record/gratitude', builder: (_, __) => const GratitudeInputScreen()),
    GoRoute(path: '/record/close', builder: (_, __) => const CloseDayScreen()),

    // 일기 상세보기 — 홈·나의 나무·감정 정원·아카이브가 모두 이 라우트로 모인다.
    GoRoute(
      path: '/record/detail/:date',
      builder: (_, state) => RecordDetailScreen(date: state.pathParameters['date']!),
    ),

    GoRoute(path: '/archive/favorites', builder: (_, __) => const FavoritesScreen()),

    // 하단 탭 — 홈 / 나의 나무 / 감정 정원 / 기록 (＋는 FAB이라 branch 아님)
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AppBottomNavShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/tree', builder: (_, __) => const MyTreeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/garden', builder: (_, __) => const EmotionGardenScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/archive', builder: (_, __) => const ArchiveScreen()),
        ]),
      ],
    ),
  ],
);
