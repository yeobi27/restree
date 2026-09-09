/// 설계서 v1.4 §4.1 — 목업 실측 기준으로 정정된 입력 제한값.
/// (v1.3까지는 세 필드 모두 200자로 잘못 기재되어 있었음)
class AppLimits {
  AppLimits._();

  /// 04단계 "오늘 가장 기억에 남는 장면은?"
  static const sceneTextMax = 500;

  /// 05단계 "오늘 고마웠던 것은?"
  static const gratitudeTextMax = 500;

  /// 05단계 "오늘의 나에게 한마디"
  static const messageToSelfMax = 30;

  /// 04단계 사진 첨부 최대 장수 (v1.4 §2 ⑤)
  static const photoMaxCount = 10;

  /// 연간 탭 "올해의 한 장면 BEST 3" (v1.2 §5)
  static const yearHighlightCount = 3;
}
