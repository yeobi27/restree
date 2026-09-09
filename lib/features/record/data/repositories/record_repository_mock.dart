import 'package:restree/core/constants/emotion.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/record/domain/repositories/record_repository.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/domain/entities/tree_state.dart';

/// Firebase 연결 전 화면 확인용 임시 구현체.
/// 목업 스크린샷의 수치(8월 22일 기록, 최고 연속 7일, 감정 분포 등)를 그대로 재현한다.
///
/// TODO: FirestoreRecordRepository 작성 후 record_providers.dart의
/// recordRepositoryProvider 한 줄만 교체하면 된다.
class RecordRepositoryMock implements RecordRepository {
  final Map<String, DailyRecord> _store = {};

  RecordRepositoryMock() {
    _seed();
  }

  void _seed() {
    // 목업 "나의 기록" 리스트 및 감정 정원 캘린더와 일치하는 8월 데이터
    final seeds = <(String, Emotion, String, List<String>, int)>[
      ('2026-08-26', Emotion.good, '오랜만에 친구를 만나서 정말 즐거운 하루였다. 같이 산책도 하면서 얘기도 많이하고 바람도 선선하고 하늘도 맑아서 마음이 한결 가벼워지는 기분이었다.', ['친구', '만남', '행복'], 3),
      ('2026-08-25', Emotion.normal, '회사에서 새로운 프로젝트가 시작되었다. 설레기도 하고 걱정도 되는 하루.', ['도전', '설렘', '성장'], 0),
      ('2026-08-24', Emotion.comfortable, '몸이 좀 피곤했지만 운동을 해서 상쾌했다!', ['운동', '상쾌'], 1),
      ('2026-08-23', Emotion.good, '가족들과 맛있는 식사! 행복한 시간을 보냈다.', ['가족', '식사'], 3),
      ('2026-08-22', Emotion.hard, '혼자만의 시간이 필요했던 하루.', ['휴식'], 0),
      ('2026-08-21', Emotion.good, '책 읽으며 힐링했다.', ['독서'], 0),
      ('2026-08-19', Emotion.comfortable, '평범하지만 편안한 하루.', ['일상'], 0),
      ('2026-08-18', Emotion.tired, '일이 많아 지친 날.', ['업무'], 0),
    ];

    for (final (date, emotion, scene, keywords, photoCount) in seeds) {
      _store[date] = DailyRecord(
        date: date,
        emotion: emotion,
        sceneText: scene,
        gratitudeText: '맛있는 저녁을 함께 먹어준 친구',
        messageToSelf: '오늘의 감정을 잊지 말자',
        keywords: keywords,
        imageUrls: List.generate(photoCount, (i) => 'mock://photo/$date/$i'),
        isFavorite: date == '2026-08-26',
        leafType: emotion.name,
        createdAt: DateTime.parse(date),
        updatedAt: DateTime.parse(date),
      );
    }
  }

  @override
  Future<void> saveRecord(DailyRecord record) async {
    _store[record.date] = record;
  }

  @override
  Future<DailyRecord?> getRecordByDate(String date) async {
    final r = _store[date];
    return (r == null || r.isDeleted) ? null : r;
  }

  @override
  Future<List<DailyRecord>> getRecordsInRange(DateTime start, DateTime end) async {
    return _store.values.where((r) {
      if (r.isDeleted) return false;
      final d = DateTime.parse(r.date);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> softDeleteRecord(String date) async {
    final r = _store[date];
    if (r != null) {
      _store[date] = r.copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> toggleFavorite(String date, bool isFavorite) async {
    final r = _store[date];
    if (r != null) {
      _store[date] = r.copyWith(isFavorite: isFavorite);
    }
  }

  @override
  Future<List<DailyRecord>> getFavorites() async {
    return _store.values.where((r) => !r.isDeleted && r.isFavorite).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Stream<TreeState> watchTreeState() async* {
    yield TreeState(
      level: TreeLevel.fullTree,
      forestStage: '나무 한 그루',
      totalRecordDays: 22,
      currentStreak: 5, // 홈화면 "연속 기록 5일"
      longestStreak: 14,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<StatsPeriodic> getStatsPeriodic(PeriodType type, String periodKey) async {
    return switch (type) {
      PeriodType.week => _weekStats(periodKey),
      PeriodType.month => _monthStats(periodKey),
      PeriodType.year => _yearStats(periodKey),
    };
  }

  StatsPeriodic _weekStats(String periodKey) => StatsPeriodic(
        periodType: PeriodType.week,
        periodKey: periodKey,
        periodStart: DateTime(2026, 8, 24),
        periodEnd: DateTime(2026, 8, 30),
        daysRecorded: 5,
        streakAtPeriodEnd: 3,
        longestStreakInPeriod: 3,
        emotionDistribution: const {
          Emotion.good: EmotionCount(count: 2, percentage: 0.29),
          Emotion.comfortable: EmotionCount(count: 3, percentage: 0.43),
          Emotion.normal: EmotionCount(count: 1, percentage: 0.14),
          Emotion.tired: EmotionCount(count: 1, percentage: 0.14),
          Emotion.hard: EmotionCount(count: 0, percentage: 0.0),
        },
        dominantEmotion: Emotion.comfortable,
        weeklyTreeStage: StatsPeriodic.stageForDays(5),
        highlightRecordIds: const ['2026-08-26'],
        aiSummary: '이번 주도 나를 잘 돌봐주었어요.',
        computedAt: DateTime.now(),
      );

  // 목업 "감정 정원 월간": 좋음 10일(45%) / 편안함 4일(18%) / 보통 5일(23%) / 지침 2일(9%) / 힘듦 1일(5%)
  // 목업 "나의 나무 월간": 기록한 날 22/31일, 최고 연속 기록 7일
  StatsPeriodic _monthStats(String periodKey) => StatsPeriodic(
        periodType: PeriodType.month,
        periodKey: periodKey,
        periodStart: DateTime(2026, 8, 1),
        periodEnd: DateTime(2026, 8, 31),
        daysRecorded: 22,
        streakAtPeriodEnd: 5,
        longestStreakInPeriod: 7,
        emotionDistribution: const {
          Emotion.good: EmotionCount(count: 10, percentage: 0.45),
          Emotion.comfortable: EmotionCount(count: 4, percentage: 0.18),
          Emotion.normal: EmotionCount(count: 5, percentage: 0.23),
          Emotion.tired: EmotionCount(count: 2, percentage: 0.09),
          Emotion.hard: EmotionCount(count: 1, percentage: 0.05),
        },
        dominantEmotion: Emotion.good,
        highlightRecordIds: const ['2026-08-26'],
        aiSummary: '평소보다 여유를 찾고, 나를 돌본 시간이 많았네요.',
        computedAt: DateTime.now(),
      );

  // 목업 "연간 탭": 247일 기록, 최장 연속 14일, 가장 오래 기록한 달 8월 26일
  StatsPeriodic _yearStats(String periodKey) {
    const monthDays = [18, 16, 20, 19, 21, 22, 24, 26, 22, 20, 19, 20];
    return StatsPeriodic(
      periodType: PeriodType.year,
      periodKey: periodKey,
      periodStart: DateTime(2026, 1, 1),
      periodEnd: DateTime(2026, 12, 31),
      daysRecorded: 247,
      streakAtPeriodEnd: 5,
      longestStreakInPeriod: 14,
      emotionDistribution: const {
        Emotion.good: EmotionCount(count: 69, percentage: 0.28),
        Emotion.comfortable: EmotionCount(count: 94, percentage: 0.38),
        Emotion.normal: EmotionCount(count: 49, percentage: 0.20),
        Emotion.tired: EmotionCount(count: 25, percentage: 0.10),
        Emotion.hard: EmotionCount(count: 10, percentage: 0.04),
      },
      dominantEmotion: Emotion.comfortable,
      periodTreeLevel: TreeLevel.bigTree,
      monthlyBreakdown: List.generate(12, (i) {
        final days = monthDays[i];
        return MonthlySummary(
          month: i + 1,
          daysRecorded: days,
          density: days >= 22
              ? MonthDensity.high
              : (days >= 19 ? MonthDensity.medium : MonthDensity.low),
          dominantEmotion: Emotion.values[i % Emotion.values.length],
        );
      }),
      highlightRecordIds: const ['2026-08-03', '2026-04-26', '2026-11-07'],
      aiSummary: '올해도 잘 자랐어요. 내년에도 당신의 나무가 더 아름답게 자라길 응원할게요!',
      computedAt: DateTime.now(),
    );
  }
}
