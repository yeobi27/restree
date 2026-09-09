import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/features/record/data/repositories/record_repository_mock.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/record/domain/repositories/record_repository.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/domain/entities/tree_state.dart';

/// TODO: Firebase 연동 시 이 한 줄만 FirestoreRecordRepository(...)로 교체
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepositoryMock();
});

final treeStateProvider = StreamProvider<TreeState>((ref) {
  return ref.watch(recordRepositoryProvider).watchTreeState();
});

final statsPeriodicProvider =
    FutureProvider.family<StatsPeriodic, (PeriodType, String)>((ref, args) {
  final (type, key) = args;
  return ref.watch(recordRepositoryProvider).getStatsPeriodic(type, key);
});

final recordsInRangeProvider =
    FutureProvider.family<List<DailyRecord>, (DateTime, DateTime)>((ref, range) {
  final (start, end) = range;
  return ref.watch(recordRepositoryProvider).getRecordsInRange(start, end);
});

final recordByDateProvider = FutureProvider.family<DailyRecord?, String>((ref, date) {
  return ref.watch(recordRepositoryProvider).getRecordByDate(date);
});

final favoriteRecordsProvider = FutureProvider<List<DailyRecord>>((ref) {
  return ref.watch(recordRepositoryProvider).getFavorites();
});

/// 03~05단계 사이에서 입력값을 들고 다니는 임시 상태.
///
/// - 신규 작성: 06~07(하루 닫기)까지 진행 후 저장
/// - 수정(v1.5 §4): 06~07을 건너뛰고 05단계의 "저장"에서 바로 저장
/// - "아직 수정할게 있어요"(v1.3 §3.3): 03단계로 돌아가되 이 값은 유지
class RecordDraft {
  /// null이면 신규 작성, 값이 있으면 해당 날짜 레코드의 수정 모드.
  final String? editingDate;

  final Emotion? emotion;
  final String sceneText;
  final String gratitudeText;
  final String messageToSelf;
  final List<String> imageUrls;

  const RecordDraft({
    this.editingDate,
    this.emotion,
    this.sceneText = '',
    this.gratitudeText = '',
    this.messageToSelf = '',
    this.imageUrls = const [],
  });

  bool get isEditing => editingDate != null;

  RecordDraft copyWith({
    String? editingDate,
    Emotion? emotion,
    String? sceneText,
    String? gratitudeText,
    String? messageToSelf,
    List<String>? imageUrls,
  }) =>
      RecordDraft(
        editingDate: editingDate ?? this.editingDate,
        emotion: emotion ?? this.emotion,
        sceneText: sceneText ?? this.sceneText,
        gratitudeText: gratitudeText ?? this.gratitudeText,
        messageToSelf: messageToSelf ?? this.messageToSelf,
        imageUrls: imageUrls ?? this.imageUrls,
      );
}

class RecordDraftNotifier extends Notifier<RecordDraft> {
  @override
  RecordDraft build() => const RecordDraft();

  void setEmotion(Emotion e) => state = state.copyWith(emotion: e);
  void setScene(String text) => state = state.copyWith(sceneText: text);
  void setGratitude(String text) => state = state.copyWith(gratitudeText: text);
  void setMessageToSelf(String text) => state = state.copyWith(messageToSelf: text);
  void setImages(List<String> urls) => state = state.copyWith(imageUrls: urls);

  /// 케밥 메뉴 › 수정 진입 시 기존 레코드 값을 프리필 (v1.5 §4)
  void loadForEdit(DailyRecord record) {
    state = RecordDraft(
      editingDate: record.date,
      emotion: record.emotion,
      sceneText: record.sceneText,
      gratitudeText: record.gratitudeText,
      messageToSelf: record.messageToSelf,
      imageUrls: record.imageUrls,
    );
  }

  void reset() => state = const RecordDraft();

  /// 신규 작성(하루 닫기) / 수정 저장 공통 진입점.
  ///
  /// keywords는 넘기지 않는다 — AI가 서버에서 채우는 읽기 전용 필드이며,
  /// 수정 시에도 서버가 본문 변경을 감지해 재추출한다(v1.5 §5.1).
  Future<void> commit(RecordRepository repo) async {
    final draft = state;
    final now = DateTime.now();
    final dateKey = draft.editingDate ?? _formatDate(now);

    final existing = draft.isEditing ? await repo.getRecordByDate(dateKey) : null;

    await repo.saveRecord(DailyRecord(
      date: dateKey,
      emotion: draft.emotion!,
      sceneText: draft.sceneText,
      gratitudeText: draft.gratitudeText,
      messageToSelf: draft.messageToSelf,
      keywords: existing?.keywords ?? const [],
      imageUrls: draft.imageUrls,
      isFavorite: existing?.isFavorite ?? false,
      leafType: draft.emotion!.name,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    ));
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final recordDraftProvider = NotifierProvider<RecordDraftNotifier, RecordDraft>(
  RecordDraftNotifier.new,
);
