// 최종 수정: 2026-10-12
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restree/core/constants/app_config.dart';
import 'package:restree/core/utils/kst.dart';
import 'package:restree/features/auth/presentation/providers/auth_providers.dart';
import 'package:restree/features/record/data/repositories/record_repository_firestore.dart';
import 'package:restree/core/constants/emotion.dart';
import 'package:restree/features/record/data/repositories/record_repository_mock.dart';
import 'package:restree/features/record/domain/entities/daily_record.dart';
import 'package:restree/features/record/domain/repositories/record_repository.dart';
import 'package:restree/features/tree/domain/entities/stats_periodic.dart';
import 'package:restree/features/tree/domain/entities/tree_state.dart';

/// kUseMockData(app_config.dart)로 Mock / Firestore를 전환한다.
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  if (kUseMockData) return RecordRepositoryMock();

  // 로그인 계정이 바뀌면(로그아웃 후 다른 계정으로 로그인 등) 이 provider와 하위 provider를
  // 새로 만들어야 이전 사용자의 데이터가 남지 않는다. "바뀌었다는 사실"만 감지한다.
  // 스트림의 첫 값이 도착하기 전에도 현재 uid를 값으로 쓰는 이유: 안 그러면 앱을 켠 직후
  // (대기 중 → uid)로 값이 바뀐 것으로 보여서 저장소가 한 번 더 만들어지고 읽기가 중복된다.
  ref.watch(authUidProvider.select((a) => a.valueOrNull ?? FirebaseAuth.instance.currentUser?.uid));

  // 값은 스트림이 아니라 currentUser에서 바로 읽는다. 스트림 값은 로그인 직후 한 박자 늦을 수 있다.
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw StateError('로그인이 필요해요.');
  return FirestoreRecordRepository(firestore: FirebaseFirestore.instance, uid: uid);
});

/// 기록이 바뀐 뒤(작성·수정·삭제·즐겨찾기) 화면 캐시를 한 번에 무효화한다.
/// family provider는 인자 없이 넘기면 모든 인스턴스가 무효화된다.
void invalidateRecordCaches(WidgetRef ref) {
  ref.invalidate(recordByDateProvider);
  ref.invalidate(recordsInRangeProvider);
  ref.invalidate(favoriteRecordsProvider);
  // statsPeriodicProvider / treeStateProvider는 실시간 구독이라 무효화하지 않는다.
  // (서버가 문서를 갱신하면 알아서 화면이 바뀐다)
}

final treeStateProvider = StreamProvider<TreeState>((ref) {
  return ref.watch(recordRepositoryProvider).watchTreeState();
});

/// 통계는 서버가 계산을 마치는 순간 화면이 바뀌도록 실시간으로 구독한다.
/// autoDispose: 화면을 벗어나면 구독을 닫는다(기간을 넘겨 보는 동안 구독이 쌓이지 않게).
final statsPeriodicProvider =
    StreamProvider.autoDispose.family<StatsPeriodic, (PeriodType, String)>((ref, args) {
  final (type, key) = args;
  return ref.watch(recordRepositoryProvider).watchStatsPeriodic(type, key);
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
    final now = DateTime.now(); // createdAt/updatedAt은 실제 시점(instant)
    final dateKey = draft.editingDate ?? kstTodayKey(); // 날짜 키는 KST 기준

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
}

final recordDraftProvider = NotifierProvider<RecordDraftNotifier, RecordDraft>(
  RecordDraftNotifier.new,
);
