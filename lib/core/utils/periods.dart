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
