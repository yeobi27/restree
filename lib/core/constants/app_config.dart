// 최종 수정: 2026-10-12

/// true: 가짜(Mock) 데이터로 화면만 확인 / false: Firestore 사용.
///
/// Firebase 없이 UI만 만져보고 싶을 때(예: 통계 화면 디자인 확인) true로 바꾸면 된다.
/// 통계(treeState/statsPeriodic)는 Cloud Functions가 만들기 전까지 Firestore 모드에서는
/// 비어 보이므로, 그 화면들은 Mock 모드로 보는 편이 낫다.
const bool kUseMockData = false;
