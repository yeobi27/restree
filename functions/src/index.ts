// 최종 수정: 2026-10-12
//
// RESTREE Cloud Functions — 통계 계산 (설계서 v1.1 §7, v1.4 §4.2, v1.5 §3)
//
// 기록(users/{uid}/records/{date})이 생성·수정·삭제될 때 서버가
//   - users/{uid}/treeState/current
//   - users/{uid}/statsPeriodic/{주·월·연 키}
// 를 다시 계산해서 쓴다. 클라이언트는 이 문서들을 읽기만 한다 (보안 규칙으로도 막혀 있음).

import {initializeApp} from "firebase-admin/app";
import {DocumentSnapshot, getFirestore, Timestamp} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

import {
  RecordLite,
  computePeriodStats,
  computeTreeState,
  isEmotion,
  kstTodayKey,
  monthRangeOf,
  weekRangeOf,
  yearRangeOf,
} from "./stats";

initializeApp();

// Firestore 데이터베이스와 같은 서울 리전. 폭주 시 비용 방어용으로 인스턴스 수도 제한한다.
const REGION = "asia-northeast3";
setGlobalOptions({region: REGION, maxInstances: 10});

/**
 * 통계에 영향을 주는 값만 뽑은 "서명". 이 값이 그대로면 재계산하지 않는다.
 *  - 소프트 삭제됐거나 없는 문서 → null
 *  - 그 외 → 감정 + 사진 유무
 * 본문 수정, 즐겨찾기 토글, (나중에 추가될) AI keywords 기록은 통계를 안 바꾸므로 건너뛴다.
 */
function signatureOf(snap: DocumentSnapshot): string | null {
  if (!snap.exists) return null;
  const d = snap.data() ?? {};
  if (d.deletedAt != null) return null;
  const hasPhoto = Array.isArray(d.imageUrls) && d.imageUrls.length > 0;
  return `${d.emotion}|${hasPhoto}`;
}

export const onRecordWritten = onDocumentWritten(
  // 일부 버전에서 setGlobalOptions의 region이 Firestore 트리거에 적용되지 않는 사례가 보고돼서
  // 트리거 옵션에도 region을 직접 적는다.
  {document: "users/{uid}/records/{date}", region: REGION},
  async (event) => {
    const change = event.data;
    if (!change) return;

    const {uid, date} = event.params;
    if (signatureOf(change.before) === signatureOf(change.after)) {
      logger.debug("통계에 영향 없는 변경 — 건너뜀", {uid, date});
      return;
    }

    await recomputeStats(uid, date);
    logger.info("통계 재계산 완료", {uid, date});
  },
);

/**
 * 사용자의 모든 기록을 한 번 읽어서 treeState와, 변경된 날짜가 속한 주·월·연 통계를 다시 쓴다.
 * 기록은 하루 1건이라 사용자당 수백~수천 건이 상한이므로, 증분 계산 대신
 * "항상 처음부터 계산"해서 삭제·덮어쓰기·수정이 섞여도 결과가 어긋나지 않게 했다.
 * (사용자와 기록이 크게 늘면 그때 증분 방식으로 최적화)
 */
async function recomputeStats(uid: string, changedDate: string): Promise<void> {
  const db = getFirestore();
  const userRef = db.doc(`users/${uid}`);

  const snap = await userRef.collection("records").select("emotion", "deletedAt", "imageUrls").get();

  const records: RecordLite[] = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.deletedAt != null) continue; // 소프트 삭제는 통계에서 제외
    if (!isEmotion(d.emotion)) continue;
    records.push({
      date: doc.id, // 문서 ID가 곧 KST 날짜 키
      emotion: d.emotion,
      hasPhoto: Array.isArray(d.imageUrls) && d.imageUrls.length > 0,
    });
  }

  const today = kstTodayKey();
  const now = Timestamp.now();
  const batch = db.batch();

  // merge: true — 나중에 추가될 aiSummary 같은 다른 필드를 지우지 않기 위해
  batch.set(
    userRef.collection("treeState").doc("current"),
    {...computeTreeState(records), updatedAt: now},
    {merge: true},
  );

  for (const range of [weekRangeOf(changedDate), monthRangeOf(changedDate), yearRangeOf(changedDate)]) {
    batch.set(
      userRef.collection("statsPeriodic").doc(range.key),
      {...computePeriodStats(range, records, today), computedAt: now},
      {merge: true},
    );
  }

  await batch.commit();
}
