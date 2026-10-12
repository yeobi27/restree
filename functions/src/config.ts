// 최종 수정: 2026-10-12
//
// 통계 계산에 쓰는 기준값을 한 곳에 모았다. 값만 바꾸면 되도록 로직과 분리한다.
// ⚠️ 아래 임계값은 설계서에 확정된 숫자가 없어 PRD 문구("1주 → 새싹, 1개월 → 작은 나무,
//    3개월 → 풍성한 나무, 1년 → 큰 나무")를 "누적 기록일수" 기준으로 옮긴 가정이다.
//    (설계서 v1.2 §14의 미결 항목 periodTreeLevel 임계값과 같은 문제)

export type TreeLevel = "seed" | "sprout" | "smallTree" | "fullTree" | "bigTree";

/** 위에서부터 검사해서 처음 만족하는 단계를 쓴다. 모두 못 넘으면 seed. */
export const LEVEL_THRESHOLDS: ReadonlyArray<{level: TreeLevel; minDays: number}> = [
  {level: "bigTree", minDays: 365},
  {level: "fullTree", minDays: 90},
  {level: "smallTree", minDays: 30},
  {level: "sprout", minDays: 7},
];

/** 연간 탭(periodTreeLevel)용. 우선 누적 기준과 동일하게 적용 — 확정되면 여기만 수정. */
export const YEAR_LEVEL_THRESHOLDS = LEVEL_THRESHOLDS;

/** forestStage — PRD: 1일(나뭇잎) → 1주(작은 나무) → 1개월(나무 한 그루) → 1년(나의 숲) */
export const FOREST_STAGES: ReadonlyArray<{stage: string; minDays: number}> = [
  {stage: "나의 숲", minDays: 365},
  {stage: "나무 한 그루", minDays: 30},
  {stage: "작은 나무", minDays: 7},
];
export const FOREST_STAGE_DEFAULT = "나뭇잎";

/** 연간 탭 "월별 기록 현황"의 잎 크기: 그 달 기록일수 ÷ 그 달 일수 */
export const DENSITY_RATIO = {high: 0.7, medium: 0.4};

/** 하이라이트로 뽑는 기록 수 (week/month는 1개, year는 BEST 3) */
export const HIGHLIGHT_COUNT = {week: 1, month: 1, year: 3};

/** 앱 날짜 기준과 동일하게 KST(UTC+9) 고정 */
export const KST_OFFSET_HOURS = 9;
