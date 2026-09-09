import 'package:restree/core/constants/emotion.dart';
import 'package:restree/features/tree/domain/entities/tree_state.dart';

/// periodKey 형식 — 설계서 v1.2 §5.1
/// week: "2026-W35" / month: "2026-08" / year: "2026"
enum PeriodType { week, month, year }

extension PeriodTypeX on PeriodType {
  String get tabLabel => switch (this) {
        PeriodType.week => '주간',
        PeriodType.month => '월간',
        PeriodType.year => '연간',
      };
}

/// statsPeriodic(year).monthlyBreakdown 의 원소 — v1.2 §5.1.
/// 연간 탭의 "월별 기록 현황"(원형 12개월)과 "월별 나무 성장 기록"에 사용.
enum MonthDensity { high, medium, low }

extension MonthDensityX on MonthDensity {
  String get label => switch (this) {
        MonthDensity.high => '기록 많음',
        MonthDensity.medium => '보통',
        MonthDensity.low => '기록 적음',
      };

  static MonthDensity fromKey(String key) =>
      MonthDensity.values.firstWhere((e) => e.name == key, orElse: () => MonthDensity.low);
}

class MonthlySummary {
  final int month; // 1~12
  final int daysRecorded;
  final MonthDensity density;
  final Emotion? dominantEmotion;

  const MonthlySummary({
    required this.month,
    required this.daysRecorded,
    required this.density,
    this.dominantEmotion,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        month: json['month'] as int,
        daysRecorded: json['daysRecorded'] as int? ?? 0,
        density: MonthDensityX.fromKey(json['density'] as String? ?? 'low'),
        dominantEmotion: json['dominantEmotion'] == null
            ? null
            : EmotionX.fromKey(json['dominantEmotion'] as String),
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'daysRecorded': daysRecorded,
        'density': density.name,
        'dominantEmotion': dominantEmotion?.name,
      };
}

/// users/{uid}/statsPeriodic/{periodKey}
/// "나의 나무"·"감정 정원"의 주간/월간/연간 탭이 공유하는 통합 문서.
class StatsPeriodic {
  final PeriodType periodType;
  final String periodKey;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int daysRecorded;

  /// 기간 종료 시점의 연속기록 스냅샷
  final int streakAtPeriodEnd;

  /// 기간 내 달성한 최장 연속기록 (v1.2) — 월간 탭 "최고 연속 기록",
  /// 연간 탭 "연속 기록 최장"에 대응. streakAtPeriodEnd와 별개 값.
  final int longestStreakInPeriod;

  final Map<Emotion, EmotionCount> emotionDistribution;
  final Emotion? dominantEmotion;

  /// week 전용 — "0~1일" / "2~3일" / "4~5일" / "6~7일"
  final String? weeklyTreeStage;

  /// year 전용 — 해당 연도 기록일수 기준으로 재산정한 나무 단계 (v1.2)
  final TreeLevel? periodTreeLevel;

  /// year 전용 — 12개월분 요약 (v1.2)
  final List<MonthlySummary> monthlyBreakdown;

  /// 시스템이 자동 선정하는 하이라이트 (v1.2에서 단일값→리스트로 변경).
  /// week=보통 1개, year="BEST 3" 최대 3개.
  /// 사용자가 수동 지정하는 records.isFavorite와는 다른 개념.
  final List<String> highlightRecordIds;

  /// AI 생성 요약 — v1.5 §5.2에 따라 감정 정원 화면에서만 사용한다.
  /// (홈 화면은 AI 생성 문구 없이 고정 카피 사용)
  final String? aiSummary;

  final DateTime computedAt;

  const StatsPeriodic({
    required this.periodType,
    required this.periodKey,
    required this.periodStart,
    required this.periodEnd,
    required this.daysRecorded,
    required this.streakAtPeriodEnd,
    required this.longestStreakInPeriod,
    required this.emotionDistribution,
    this.dominantEmotion,
    this.weeklyTreeStage,
    this.periodTreeLevel,
    this.monthlyBreakdown = const [],
    this.highlightRecordIds = const [],
    this.aiSummary,
    required this.computedAt,
  });

  bool get isEmpty => daysRecorded == 0;

  /// 주간 나무 단계 구간 산정 — 목업 "0~1일 / 2~3일 / 4~5일 / 6~7일"
  static String stageForDays(int days) {
    if (days <= 1) return '0~1일';
    if (days <= 3) return '2~3일';
    if (days <= 5) return '4~5일';
    return '6~7일';
  }

  /// 연간 탭 "가장 오래 기록한 달" — v1.2 §5.1 비고에 따라
  /// 별도 필드로 캐시하지 않고 monthlyBreakdown에서 클라이언트가 계산.
  MonthlySummary? get busiestMonth {
    if (monthlyBreakdown.isEmpty) return null;
    return monthlyBreakdown
        .reduce((a, b) => b.daysRecorded > a.daysRecorded ? b : a);
  }

  factory StatsPeriodic.fromJson(Map<String, dynamic> json) => StatsPeriodic(
        periodType: PeriodType.values.firstWhere((e) => e.name == json['periodType']),
        periodKey: json['periodKey'] as String,
        periodStart: DateTime.parse(json['periodStart'] as String),
        periodEnd: DateTime.parse(json['periodEnd'] as String),
        daysRecorded: json['daysRecorded'] as int? ?? 0,
        streakAtPeriodEnd: json['streakAtPeriodEnd'] as int? ?? 0,
        longestStreakInPeriod: json['longestStreakInPeriod'] as int? ?? 0,
        emotionDistribution: (json['emotionDistribution'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(EmotionX.fromKey(k), EmotionCount.fromJson(v))),
        dominantEmotion: json['dominantEmotion'] == null
            ? null
            : EmotionX.fromKey(json['dominantEmotion'] as String),
        weeklyTreeStage: json['weeklyTreeStage'] as String?,
        periodTreeLevel: json['periodTreeLevel'] == null
            ? null
            : TreeLevelX.fromKey(json['periodTreeLevel'] as String),
        monthlyBreakdown: (json['monthlyBreakdown'] as List?)
                ?.map((e) => MonthlySummary.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        highlightRecordIds: (json['highlightRecordIds'] as List?)?.cast<String>() ?? const [],
        aiSummary: json['aiSummary'] as String?,
        computedAt: DateTime.parse(json['computedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'periodType': periodType.name,
        'periodKey': periodKey,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'daysRecorded': daysRecorded,
        'streakAtPeriodEnd': streakAtPeriodEnd,
        'longestStreakInPeriod': longestStreakInPeriod,
        'emotionDistribution': emotionDistribution.map((k, v) => MapEntry(k.name, v.toJson())),
        'dominantEmotion': dominantEmotion?.name,
        'weeklyTreeStage': weeklyTreeStage,
        'periodTreeLevel': periodTreeLevel?.name,
        'monthlyBreakdown': monthlyBreakdown.map((e) => e.toJson()).toList(),
        'highlightRecordIds': highlightRecordIds,
        'aiSummary': aiSummary,
        'computedAt': computedAt.toIso8601String(),
      };
}
