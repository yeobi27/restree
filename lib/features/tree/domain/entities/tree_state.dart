// 최종 수정: 2026-10-12
/// 나무 성장 5단계 — 전체 누적 기준(treeState.level)과
/// 연도 기준(statsPeriodic.periodTreeLevel)이 같은 스케일을 공유한다.
enum TreeLevel { seed, sprout, smallTree, fullTree, bigTree }

extension TreeLevelX on TreeLevel {
  String get label => switch (this) {
        TreeLevel.seed => '씨앗',
        TreeLevel.sprout => '새싹',
        TreeLevel.smallTree => '작은 나무',
        TreeLevel.fullTree => '풍성한 나무',
        TreeLevel.bigTree => '큰 나무',
      };

  static TreeLevel fromKey(String key) =>
      TreeLevel.values.firstWhere((e) => e.name == key, orElse: () => TreeLevel.seed);
}

/// users/{uid}/treeState — 전체 누적(라이프타임) 나무 상태 단일 문서.
class TreeState {
  final TreeLevel level;
  final String forestStage;
  final int totalRecordDays;
  final int currentStreak;
  final int longestStreak;

  /// 마지막 기록일('yyyy-MM-dd', KST). 서버가 채운다.
  /// 연속 기록이 아직 이어지는지 판단하는 데 쓴다 — [effectiveStreak] 참고.
  final String? lastRecordDate;
  final DateTime updatedAt;

  const TreeState({
    required this.level,
    required this.forestStage,
    required this.totalRecordDays,
    required this.currentStreak,
    required this.longestStreak,
    this.lastRecordDate,
    required this.updatedAt,
  });

  bool get isEmpty => totalRecordDays == 0;

  /// 화면에 보여줄 연속 기록.
  ///
  /// 서버는 "마지막 기록일에서 끝나는 연속 길이"만 저장한다(자정마다 도는 배치가 없다).
  /// 그래서 마지막 기록일이 어제보다 이전이면 이미 끊긴 것으로 보고 0을 돌려준다.
  /// - 오늘 기록함      → 마지막 기록일 = 오늘  → 이어짐
  /// - 오늘은 아직 안 씀 → 마지막 기록일 = 어제  → 아직 이어지는 중(오늘 안에 쓰면 +1)
  /// - 그 이전          → 끊김 → 0
  /// lastRecordDate가 없으면(Mock 등) 저장된 값을 그대로 쓴다.
  int effectiveStreak(String yesterdayKey) {
    final last = lastRecordDate;
    if (last == null) return currentStreak;
    return last.compareTo(yesterdayKey) >= 0 ? currentStreak : 0;
  }

  factory TreeState.fromJson(Map<String, dynamic> json) => TreeState(
        level: TreeLevelX.fromKey(json['level'] as String? ?? 'seed'),
        forestStage: json['forestStage'] as String? ?? '나뭇잎',
        totalRecordDays: json['totalRecordDays'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastRecordDate: json['lastRecordDate'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'forestStage': forestStage,
        'totalRecordDays': totalRecordDays,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastRecordDate': lastRecordDate,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
