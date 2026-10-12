// 최종 수정: 2026-10-12
import 'package:restree/core/constants/app_config.dart';
import 'package:restree/core/utils/kst.dart';

/// 통계 한 기간(주/월/연).
///
/// ⚠️ key 형식과 계산 규칙은 서버(functions/src/stats.ts의 weekRangeOf 등)와
/// 반드시 같아야 한다. 한쪽만 바꾸면 앱이 서버가 만든 문서를 못 찾는다.
///   주: ISO 주차, 월요일 시작  "2026-W35"
///   월: "2026-08"
///   연: "2026"
class PeriodRange {
  const PeriodRange({required this.key, required this.start, required this.end});

  final String key;

  /// 기간의 첫날/마지막날 (포함). 연·월·일만 의미가 있다(시각은 자정).
  /// provider 조회 key로도 쓰이므로 반드시 날짜만 담는다.
  final DateTime start;
  final DateTime end;
}

/// 화면이 "지금"으로 삼을 날짜. Mock 모드에서는 Mock 데이터가 있는 8월 26일로 고정한다.
DateTime viewAnchor() => kUseMockData ? DateTime(2026, 8, 26) : kstNow();

PeriodRange weekRangeOf(DateTime d) {
  final day = DateTime.utc(d.year, d.month, d.day);
  final monday = day.subtract(Duration(days: day.weekday - 1)); // weekday: 월=1 … 일=7
  final sunday = monday.add(const Duration(days: 6));
  final thursday = monday.add(const Duration(days: 3)); // ISO 주차는 목요일이 속한 해를 따른다
  final isoYear = thursday.year;
  final week = thursday.difference(DateTime.utc(isoYear, 1, 1)).inDays ~/ 7 + 1;
  return PeriodRange(
    key: '$isoYear-W${week.toString().padLeft(2, '0')}',
    start: DateTime(monday.year, monday.month, monday.day),
    end: DateTime(sunday.year, sunday.month, sunday.day),
  );
}

PeriodRange monthRangeOf(DateTime d) => PeriodRange(
      key: '${d.year}-${d.month.toString().padLeft(2, '0')}',
      start: DateTime(d.year, d.month, 1),
      end: DateTime(d.year, d.month + 1, 0),
    );

PeriodRange yearRangeOf(DateTime d) => PeriodRange(
      key: '${d.year}',
      start: DateTime(d.year, 1, 1),
      end: DateTime(d.year, 12, 31),
    );

/// 화면이 "오늘"로 삼을 날짜 (시각 없이 날짜만). provider key로 써도 안전하다.
DateTime viewToday() {
  final t = viewAnchor();
  return DateTime(t.year, t.month, t.day);
}

/// 기준 날짜를 이전(-1)/다음(+1) 기간으로 옮긴다. DateTime 생성자가 넘치는 일·월을 알아서 올림/내림한다.
DateTime shiftWeek(DateTime a, int delta) => DateTime(a.year, a.month, a.day + 7 * delta);
DateTime shiftMonth(DateTime a, int delta) => DateTime(a.year, a.month + delta, 1);
DateTime shiftYear(DateTime a, int delta) => DateTime(a.year + delta, 1, 1);

/// 주간 라벨 — 올해가 아니면 연도를 앞에 붙여서 다른 해로 넘어가도 헷갈리지 않게 한다.
String weekLabel(PeriodRange r) {
  final yearPart = r.start.year != viewToday().year ? '${r.start.year}년 ' : '';
  return '$yearPart${r.start.month}월 ${r.start.day}일 - ${r.end.month}월 ${r.end.day}일';
}
