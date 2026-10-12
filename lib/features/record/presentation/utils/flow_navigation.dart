// 최종 수정: 2026-10-12
import 'package:go_router/go_router.dart';

/// 수정 플로우(03~05단계)에서 빠져나와 상세보기로 돌아간다.
///
/// 수정은 상세보기에서 push로 들어가므로 화면이 이렇게 쌓인다:
///   [... 홈/아카이브 …, 상세보기, 감정 선택, 장면, 감사·한마디]
///
/// 여기서 go('/record/detail/…')를 쓰면 쌓인 화면을 전부 버려서 상세보기 한 장만 남고,
/// 그 상태에서 뒤로가기를 누르면 "There is nothing to pop" 오류가 난다.
/// 그래서 쌓인 수정 화면의 수([depth])만큼만 pop해서, 상세보기와 그 아래 화면을 그대로 보존한다.
///
/// [depth]: 감정 선택 화면에서 1, 장면 화면에서 2, 감사·한마디 화면에서 3
void popEditFlow(GoRouter router, int depth) {
  for (var i = 0; i < depth && router.canPop(); i++) {
    router.pop();
  }
}
