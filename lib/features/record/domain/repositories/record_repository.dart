import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/domain/entities/tree_state.dart';

/// Domain 레이어 — Firebase에 의존하지 않는 인터페이스.
abstract class RecordRepository {
  /// 신규 작성 및 수정 저장에 공통으로 사용.
  ///
  /// 서버 책임(클라이언트가 하지 않는 것):
  /// - treeState/statsPeriodic 재계산 (v1.4 §4.2)
  /// - keywords 추출·재추출 (v1.5 §5.1)
  Future<void> saveRecord(DailyRecord record);

  Future<DailyRecord?> getRecordByDate(String date);

  /// 소프트 삭제된 레코드는 제외하고 반환한다 (v1.5 §3).
  Future<List<DailyRecord>> getRecordsInRange(DateTime start, DateTime end);

  /// 소프트 삭제 — deletedAt만 기록하고 문서는 남긴다.
  Future<void> softDeleteRecord(String date);

  /// 즐겨찾기 토글 (v1.4 §3.2) — 클라이언트 write가 허용된 유일한 부가 필드.
  Future<void> toggleFavorite(String date, bool isFavorite);

  Future<List<DailyRecord>> getFavorites();

  Stream<TreeState> watchTreeState();

  Future<StatsPeriodic> getStatsPeriodic(PeriodType type, String periodKey);
}
