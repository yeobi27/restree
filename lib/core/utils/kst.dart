// 최종 수정: 2026-10-12
//
// 날짜 기준 통일 (결정 사항): records 문서 ID(`yyyy-MM-dd`)와 period 키는
// 기기 시간대와 무관하게 항상 KST(UTC+9) 기준으로 계산한다.
// 한국은 서머타임이 없으므로 UTC+9 고정 오프셋으로 충분하다.

/// 지금 이 순간의 "한국 시각 벽시계" 값.
///
/// 주의: 반환값은 UTC 플래그가 붙은 DateTime이지만 year/month/day/hour 필드가
/// 한국 시각을 나타낸다. 날짜 키·화면 표시용으로만 쓰고, createdAt/updatedAt 같은
/// "시점(instant)"으로 저장하면 9시간 어긋나므로 그런 곳에는 DateTime.now()를 쓴다.
DateTime kstNow() => DateTime.now().toUtc().add(const Duration(hours: 9));

/// DateTime의 연·월·일 필드를 그대로 `yyyy-MM-dd`로 만든다 (시간대 변환 없음).
String formatDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 오늘(KST)의 날짜 키.
String kstTodayKey() => formatDateKey(kstNow());
