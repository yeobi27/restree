// 최종 수정: 2026-10-12
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restree/core/utils/periods.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';

/// "지금 보고 있는 기간"의 기준 날짜.
///
/// 키는 (화면, 기간 종류)다. 화면은 'tree'(나의 나무) / 'garden'(감정 정원)이고,
/// 화면마다·주/월/연 탭마다 따로 기억한다. 처음에는 오늘이 들어 있는 기간이다.
/// 값은 항상 날짜만 담는다(시각 없음) — provider key로 쓰이기 때문이다.
final periodAnchorProvider = StateProvider.family<DateTime, (String, PeriodType)>(
  (ref, key) => viewToday(),
);
