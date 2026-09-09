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
  final DateTime updatedAt;

  const TreeState({
    required this.level,
    required this.forestStage,
    required this.totalRecordDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.updatedAt,
  });

  bool get isEmpty => totalRecordDays == 0;

  factory TreeState.fromJson(Map<String, dynamic> json) => TreeState(
        level: TreeLevelX.fromKey(json['level'] as String? ?? 'seed'),
        forestStage: json['forestStage'] as String? ?? '나뭇잎',
        totalRecordDays: json['totalRecordDays'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'forestStage': forestStage,
        'totalRecordDays': totalRecordDays,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
