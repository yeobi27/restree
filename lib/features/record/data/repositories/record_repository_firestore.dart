// 최종 수정: 2026-10-12
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restree/core/utils/kst.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/record/domain/repositories/record_repository.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/domain/entities/tree_state.dart';

/// RecordRepository의 Firestore 구현체.
///
/// 경로 구조 (설계서 v1.1~v1.5):
///   users/{uid}/records/{yyyy-MM-dd}
///   users/{uid}/treeState/current          ← 서버(Cloud Functions)가 갱신 (단일 문서라 ID를 current로 고정)
///   users/{uid}/statsPeriodic/{periodKey}  ← 서버(Cloud Functions)가 갱신
///
/// 클라이언트가 건드릴 수 없는 필드 (보안 규칙으로도 막혀 있음):
///   keywords(AI가 채움), createdAt·date(최초 작성 후 불변)
class FirestoreRecordRepository implements RecordRepository {
  FirestoreRecordRepository({required FirebaseFirestore firestore, required String uid})
      : _db = firestore,
        _uid = uid;

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _userDoc => _db.collection('users').doc(_uid);
  CollectionReference<Map<String, dynamic>> get _records => _userDoc.collection('records');
  DocumentReference<Map<String, dynamic>> get _treeStateDoc =>
      _userDoc.collection('treeState').doc('current');
  DocumentReference<Map<String, dynamic>> _statsDoc(String periodKey) =>
      _userDoc.collection('statsPeriodic').doc(periodKey);

  // ─────────────────────────── records ───────────────────────────

  @override
  Future<void> saveRecord(DailyRecord record) async {
    final ref = _records.doc(record.date);
    final snap = await ref.get();
    final isLive = snap.exists && snap.data()?['deletedAt'] == null;

    if (!isLive) {
      // 새 기록이거나, 소프트 삭제된 날짜에 다시 쓰는 경우.
      // set()을 merge 없이 쓰므로 문서가 통째로 교체되어 deletedAt이 null로 초기화된다.
      // (결정 사항: 삭제된 문서를 새 내용으로 덮어쓰면서 deletedAt을 비운다)
      await ref.set(_encodeRecord(record));
    } else {
      // 살아있는 기록의 수정 — 수정 가능한 필드만 갱신한다.
      // keywords / isFavorite / createdAt은 건드리지 않는다(keywords는 서버가 재추출).
      await ref.update({
        'emotion': record.emotion.name,
        'sceneText': record.sceneText,
        'gratitudeText': record.gratitudeText,
        'messageToSelf': record.messageToSelf,
        'imageUrls': record.imageUrls,
        'leafType': record.leafType,
        'updatedAt': Timestamp.fromDate(record.updatedAt),
      });
    }
  }

  @override
  Future<DailyRecord?> getRecordByDate(String date) async {
    final snap = await _records.doc(date).get();
    final data = snap.data();
    if (data == null) return null;
    final record = _decodeRecord(data);
    return record.isDeleted ? null : record;
  }

  @override
  Future<List<DailyRecord>> getRecordsInRange(DateTime start, DateTime end) async {
    // date 필드(= 문서 ID)는 yyyy-MM-dd 문자열이라 사전순 비교가 곧 날짜순 비교다.
    // 소프트 삭제 제외는 서버 쿼리가 아니라 앱에서 거른다
    // (where(deletedAt == null)을 더하면 복합 인덱스가 필요해지기 때문).
    final snap = await _records
        .where('date', isGreaterThanOrEqualTo: formatDateKey(start))
        .where('date', isLessThanOrEqualTo: formatDateKey(end))
        .get();

    return snap.docs
        .map((d) => _decodeRecord(d.data()))
        .where((r) => !r.isDeleted)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> softDeleteRecord(String date) async {
    await _records.doc(date).update({
      'deletedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> toggleFavorite(String date, bool isFavorite) async {
    await _records.doc(date).update({'isFavorite': isFavorite});
  }

  @override
  Future<List<DailyRecord>> getFavorites() async {
    final snap = await _records.where('isFavorite', isEqualTo: true).get();
    return snap.docs
        .map((d) => _decodeRecord(d.data()))
        .where((r) => !r.isDeleted)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ─────────────────── 통계 (서버가 채우는 문서) ───────────────────
  //
  // treeState / statsPeriodic은 Cloud Functions(4단계)가 만든다.
  // 그 전까지는 문서가 없으므로 "빈 상태" 값을 돌려주고, 화면은 EmptyState를 보여준다.

  @override
  Stream<TreeState> watchTreeState() {
    return _treeStateDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return _emptyTreeState();
      return TreeState.fromJson(_timestampsToIso(data, const ['updatedAt']));
    });
  }

  @override
  Future<StatsPeriodic> getStatsPeriodic(PeriodType type, String periodKey) async {
    final snap = await _statsDoc(periodKey).get();
    final data = snap.data();
    if (data == null) return _emptyStats(type, periodKey);
    return StatsPeriodic.fromJson(
      _timestampsToIso(data, const ['periodStart', 'periodEnd', 'computedAt']),
    );
  }

  // ─────────────────────────── 변환 헬퍼 ───────────────────────────

  /// 엔티티 → Firestore 문서. 날짜·시각은 ISO 문자열이 아니라 Timestamp로 저장한다.
  Map<String, dynamic> _encodeRecord(DailyRecord r) => {
        ...r.toJson(),
        'createdAt': Timestamp.fromDate(r.createdAt),
        'updatedAt': Timestamp.fromDate(r.updatedAt),
        'deletedAt': r.deletedAt == null ? null : Timestamp.fromDate(r.deletedAt!),
      };

  DailyRecord _decodeRecord(Map<String, dynamic> data) =>
      DailyRecord.fromJson(_timestampsToIso(data, const ['createdAt', 'updatedAt', 'deletedAt']));

  /// 엔티티의 fromJson은 ISO 문자열을 기대하므로, Timestamp 필드만 문자열로 바꿔 넘긴다.
  static Map<String, dynamic> _timestampsToIso(Map<String, dynamic> data, List<String> keys) {
    final out = Map<String, dynamic>.from(data);
    for (final k in keys) {
      final v = out[k];
      if (v is Timestamp) out[k] = v.toDate().toIso8601String();
    }
    return out;
  }

  TreeState _emptyTreeState() => TreeState(
        level: TreeLevel.seed,
        forestStage: '나뭇잎',
        totalRecordDays: 0,
        currentStreak: 0,
        longestStreak: 0,
        updatedAt: DateTime.now(),
      );

  StatsPeriodic _emptyStats(PeriodType type, String periodKey) {
    final now = DateTime.now();
    return StatsPeriodic(
      periodType: type,
      periodKey: periodKey,
      periodStart: now,
      periodEnd: now,
      daysRecorded: 0,
      streakAtPeriodEnd: 0,
      longestStreakInPeriod: 0,
      emotionDistribution: const {},
      computedAt: now,
    );
  }
}
