// 최종 수정: 2026-10-12
//
// 통계 계산 로직 — Firebase에 의존하지 않는 순수 함수만 모았다.
// (그래서 배포 없이 단독으로 테스트할 수 있다)
//
// 날짜는 전부 'YYYY-MM-DD' 문자열(= records 문서 ID, KST 기준)로 다룬다.
// 시간대 변환이 끼어들 여지가 없도록 내부 계산은 UTC 자정 기준 "일 번호"로 한다.

import {
  DENSITY_RATIO,
  FOREST_STAGE_DEFAULT,
  FOREST_STAGES,
  HIGHLIGHT_COUNT,
  KST_OFFSET_HOURS,
  LEVEL_THRESHOLDS,
  TreeLevel,
  YEAR_LEVEL_THRESHOLDS,
} from "./config";

export type Emotion = "good" | "comfortable" | "normal" | "tired" | "hard";
/** 앱의 Emotion enum 선언 순서와 같다 (좋음 → 힘듦). 동률일 때 앞쪽이 대표 감정. */
export const EMOTIONS: ReadonlyArray<Emotion> = ["good", "comfortable", "normal", "tired", "hard"];

export function isEmotion(v: unknown): v is Emotion {
  return typeof v === "string" && (EMOTIONS as ReadonlyArray<string>).includes(v);
}

/** 통계에 필요한 필드만 뽑은 기록 (소프트 삭제된 기록은 호출 전에 제외한다) */
export interface RecordLite {
  date: string;
  emotion: Emotion;
  hasPhoto: boolean;
}

// ───────────────────────── 날짜 유틸 ─────────────────────────

const DAY_MS = 86400000;

function pad(n: number): string {
  return String(n).padStart(2, "0");
}

export function dayNumber(dateKey: string): number {
  const [y, m, d] = dateKey.split("-").map(Number);
  return Date.UTC(y, m - 1, d) / DAY_MS;
}

export function fromDayNumber(n: number): string {
  const dt = new Date(n * DAY_MS);
  return `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}`;
}

/** 지금 이 순간의 KST 날짜 키 */
export function kstTodayKey(nowMs: number = Date.now()): string {
  return new Date(nowMs + KST_OFFSET_HOURS * 3600000).toISOString().slice(0, 10);
}

// ───────────────────────── 기간(주/월/연) ─────────────────────────

export type PeriodType = "week" | "month" | "year";

export interface PeriodRange {
  type: PeriodType;
  /** 주: "2026-W35"(ISO 주차, 월요일 시작) / 월: "2026-08" / 연: "2026" */
  key: string;
  start: string; // 'YYYY-MM-DD' (포함)
  end: string; // 'YYYY-MM-DD' (포함)
}

export function weekRangeOf(dateKey: string): PeriodRange {
  const n = dayNumber(dateKey);
  const weekday = new Date(n * DAY_MS).getUTCDay(); // 일=0 … 토=6
  const monday = n - ((weekday + 6) % 7); // 월=0 … 일=6 으로 바꿔서 월요일로 되돌린다
  const thursday = monday + 3; // ISO 주차는 그 주의 목요일이 속한 해를 따른다
  const isoYear = new Date(thursday * DAY_MS).getUTCFullYear();
  const jan1 = Date.UTC(isoYear, 0, 1) / DAY_MS;
  const week = Math.floor((thursday - jan1) / 7) + 1;
  return {
    type: "week",
    key: `${isoYear}-W${pad(week)}`,
    start: fromDayNumber(monday),
    end: fromDayNumber(monday + 6),
  };
}

export function monthRangeOf(dateKey: string): PeriodRange {
  const [y, m] = dateKey.split("-").map(Number);
  const lastDay = new Date(Date.UTC(y, m, 0)).getUTCDate();
  return {
    type: "month",
    key: `${y}-${pad(m)}`,
    start: `${y}-${pad(m)}-01`,
    end: `${y}-${pad(m)}-${pad(lastDay)}`,
  };
}

export function yearRangeOf(dateKey: string): PeriodRange {
  const y = Number(dateKey.slice(0, 4));
  return {type: "year", key: `${y}`, start: `${y}-01-01`, end: `${y}-12-31`};
}

// ───────────────────────── 연속 기록 ─────────────────────────

/** 오름차순 일 번호 배열에서 가장 긴 연속 구간 길이 */
function longestRun(sortedDays: number[]): number {
  let best = 0;
  let run = 0;
  for (let i = 0; i < sortedDays.length; i++) {
    run = i > 0 && sortedDays[i] === sortedDays[i - 1] + 1 ? run + 1 : 1;
    if (run > best) best = run;
  }
  return best;
}

/** endDay(포함)에서 거꾸로 이어지는 연속 길이 */
function runEndingAt(daySet: Set<number>, endDay: number): number {
  let count = 0;
  for (let d = endDay; daySet.has(d); d--) count++;
  return count;
}

// ───────────────────────── 나무 단계 ─────────────────────────

function levelForDays(
  days: number,
  thresholds: ReadonlyArray<{level: TreeLevel; minDays: number}>,
): TreeLevel {
  for (const t of thresholds) {
    if (days >= t.minDays) return t.level;
  }
  return "seed";
}

function forestStageForDays(days: number): string {
  for (const s of FOREST_STAGES) {
    if (days >= s.minDays) return s.stage;
  }
  return FOREST_STAGE_DEFAULT;
}

/** 앱의 StatsPeriodic.stageForDays 와 같은 구간 */
function weeklyTreeStage(days: number): string {
  if (days <= 1) return "0~1일";
  if (days <= 3) return "2~3일";
  if (days <= 5) return "4~5일";
  return "6~7일";
}

// ───────────────────────── treeState ─────────────────────────

export interface TreeStateDoc {
  level: TreeLevel;
  forestStage: string;
  totalRecordDays: number;
  /** 마지막 기록일에서 끝나는 연속 길이. 자정 배치 없이 끊김을 알 수 있도록
   *  앱이 lastRecordDate 와 어제 날짜를 비교해서 실제 표시값을 정한다. */
  currentStreak: number;
  longestStreak: number;
  lastRecordDate: string | null;
}

export function computeTreeState(records: RecordLite[]): TreeStateDoc {
  const days = Array.from(new Set(records.map((r) => dayNumber(r.date)))).sort((a, b) => a - b);
  const total = days.length;
  if (total === 0) {
    return {
      level: "seed",
      forestStage: FOREST_STAGE_DEFAULT,
      totalRecordDays: 0,
      currentStreak: 0,
      longestStreak: 0,
      lastRecordDate: null,
    };
  }
  const last = days[total - 1];
  return {
    level: levelForDays(total, LEVEL_THRESHOLDS),
    forestStage: forestStageForDays(total),
    totalRecordDays: total,
    currentStreak: runEndingAt(new Set(days), last),
    longestStreak: longestRun(days),
    lastRecordDate: fromDayNumber(last),
  };
}

// ───────────────────────── statsPeriodic ─────────────────────────

export interface MonthlySummaryDoc {
  month: number;
  daysRecorded: number;
  density: "high" | "medium" | "low";
  dominantEmotion: Emotion | null;
}

export interface PeriodStatsDoc {
  periodType: PeriodType;
  periodKey: string;
  periodStart: string; // 'YYYY-MM-DD' — 시간대 영향을 받지 않도록 문자열로 저장
  periodEnd: string;
  daysRecorded: number;
  streakAtPeriodEnd: number;
  longestStreakInPeriod: number;
  emotionDistribution: Record<Emotion, {count: number; percentage: number}>;
  dominantEmotion: Emotion | null;
  highlightRecordIds: string[];
  weeklyTreeStage?: string; // week 전용
  periodTreeLevel?: TreeLevel; // year 전용
  monthlyBreakdown?: MonthlySummaryDoc[]; // year 전용
}

function emotionStats(inRange: RecordLite[]): {
  distribution: Record<Emotion, {count: number; percentage: number}>;
  dominant: Emotion | null;
} {
  const counts: Record<Emotion, number> = {good: 0, comfortable: 0, normal: 0, tired: 0, hard: 0};
  for (const r of inRange) counts[r.emotion]++;
  const total = inRange.length;

  const distribution = {} as Record<Emotion, {count: number; percentage: number}>;
  let dominant: Emotion | null = null;
  for (const e of EMOTIONS) {
    distribution[e] = {count: counts[e], percentage: total === 0 ? 0 : counts[e] / total};
    if (counts[e] > 0 && (dominant === null || counts[e] > counts[dominant])) dominant = e;
  }
  return {distribution, dominant};
}

/** 사진이 있는 기록 우선, 그다음 최신순. (BEST의 "감정 기준 선별"은 아직 정해지지 않아 반영 안 함) */
function pickHighlights(inRange: RecordLite[], count: number): string[] {
  return [...inRange]
    .sort((a, b) => {
      if (a.hasPhoto !== b.hasPhoto) return a.hasPhoto ? -1 : 1;
      return a.date < b.date ? 1 : a.date > b.date ? -1 : 0;
    })
    .slice(0, count)
    .map((r) => r.date);
}

/**
 * 한 기간(주/월/연)의 통계를 계산한다.
 * @param allRecords 이 사용자의 모든 (삭제되지 않은) 기록 — 기간 경계를 넘는 연속 기록 계산에 필요
 * @param todayKey   오늘(KST). 진행 중인 기간의 "기간 종료 시점 연속 기록" 기준일로 쓴다.
 */
export function computePeriodStats(
  range: PeriodRange,
  allRecords: RecordLite[],
  todayKey: string,
): PeriodStatsDoc {
  const inRange = allRecords.filter((r) => r.date >= range.start && r.date <= range.end);
  const {distribution, dominant} = emotionStats(inRange);

  const allDays = new Set(allRecords.map((r) => dayNumber(r.date)));
  const periodDays = Array.from(new Set(inRange.map((r) => dayNumber(r.date)))).sort((a, b) => a - b);

  // 기간 종료 시점 연속 기록: 진행 중인 기간은 "오늘"까지만 본다.
  // 오늘 기록을 아직 안 썼으면 어제까지 이어진 연속은 살아있는 것으로 센다.
  let streakAtPeriodEnd = 0;
  const effectiveEnd = range.end < todayKey ? range.end : todayKey;
  if (effectiveEnd >= range.start) {
    let endDay = dayNumber(effectiveEnd);
    if (effectiveEnd === todayKey && !allDays.has(endDay)) endDay -= 1;
    streakAtPeriodEnd = runEndingAt(allDays, endDay);
  }

  const doc: PeriodStatsDoc = {
    periodType: range.type,
    periodKey: range.key,
    periodStart: range.start,
    periodEnd: range.end,
    daysRecorded: periodDays.length,
    streakAtPeriodEnd,
    longestStreakInPeriod: longestRun(periodDays),
    emotionDistribution: distribution,
    dominantEmotion: dominant,
    highlightRecordIds: pickHighlights(inRange, HIGHLIGHT_COUNT[range.type]),
  };

  if (range.type === "week") {
    doc.weeklyTreeStage = weeklyTreeStage(doc.daysRecorded);
  }

  if (range.type === "year") {
    doc.periodTreeLevel = levelForDays(doc.daysRecorded, YEAR_LEVEL_THRESHOLDS);
    doc.monthlyBreakdown = [];
    const year = Number(range.key);
    for (let m = 1; m <= 12; m++) {
      const monthRange = monthRangeOf(`${year}-${pad(m)}-01`);
      const monthRecords = inRange.filter((r) => r.date >= monthRange.start && r.date <= monthRange.end);
      const daysInMonth = Number(monthRange.end.slice(8, 10));
      const ratio = monthRecords.length / daysInMonth;
      doc.monthlyBreakdown.push({
        month: m,
        daysRecorded: monthRecords.length,
        density: ratio >= DENSITY_RATIO.high ? "high" : ratio >= DENSITY_RATIO.medium ? "medium" : "low",
        dominantEmotion: emotionStats(monthRecords).dominant,
      });
    }
  }

  return doc;
}
