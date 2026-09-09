# RESTREE — Flutter 뼈대 (v0.2)

설계서 **v1.0 ~ v1.5**의 확정 사항을 모두 반영한 스켈레톤입니다.
Dart 파일 38개, Clean Architecture 3계층 구조.

이 뼈대는 Flutter SDK가 없는 환경에서 작성되어 `flutter analyze`를 돌리지 못했습니다.
정적 검증(import 해석 38/38, provider 참조 10/10, const 생성자)까지만 마친 상태이니
로컬에서 `flutter pub get` 후 **`flutter analyze`를 한 번 돌려보세요.**

---

## 실행 방법 (GitHub 버전관리 포함)

`flutter create`가 android/ios 네이티브 골격과 기본 `.gitignore`, git 저장소를 함께
만들어주므로 **반드시 flutter create → 스켈레톤 덮어쓰기 → git 커밋** 순서를 지키세요.

### A. 자동 스크립트

```bash
chmod +x restree_v2/setup.sh
./restree_v2/setup.sh
```

이후 GitHub 원격 저장소 연결:

```bash
git remote add origin <your-repo-url>
git branch -M main
git push -u origin main
```

### B. 수동

```bash
flutter create restree
cd restree
rm -rf lib
cp -r ../restree_v2/lib ./lib
cp ../restree_v2/pubspec.yaml ../restree_v2/analysis_options.yaml ../restree_v2/README.md .
cat ../restree_v2/.gitignore.append >> .gitignore

flutter pub get
flutter analyze          # ← 먼저 확인
flutter run
```

> ⚠️ `flutterfire configure` 실행 시 생기는 `google-services.json`,
> `GoogleService-Info.plist`, `lib/firebase_options.dart`는
> `.gitignore.append`가 이미 제외하도록 되어 있습니다.

현재 `RecordRepositoryMock`이 목업 스크린샷과 동일한 더미 데이터
(8월 22/31일 기록, 최고 연속 7일, 좋음 45%, 연간 247일)를 반환하므로
**Firebase 연결 전에도 전체 화면 흐름을 확인**할 수 있습니다.

---

## 폴더 구조

```
lib/
  core/
    constants/  emotion.dart (5종 enum + 컬러), app_limits.dart (500/500/30자, 사진 10장)
    theme/      app_colors.dart, app_theme.dart
    router/     app_router.dart
    widgets/    app_bottom_nav.dart (5슬롯), empty_state.dart
  features/
    onboarding/ 01 시작화면 (3페이지 스와이프)
    auth/       02 로그인 (카카오/Google/Apple/이메일)
    record/     03~07 작성 플로우 + 상세보기(케밥 메뉴)
      domain/       DailyRecord, RecordRepository 인터페이스
      data/         RecordRepositoryMock
      presentation/ providers, screens, widgets
    home/       08 홈 (작성 전/후 분기)
    tree/       09 나의 나무 (주/월/연) + TreeState, StatsPeriodic 엔티티
    garden/     10 감정 정원 (주/월/연) + 식물 높이 그래프
    archive/    11 나의 기록 + 즐겨찾기
    shop/       상점 (재화/카탈로그/인벤토리)
    menu/       햄버거 메뉴 (설정·상점 진입)
```

---

## 설계서 결정사항 → 코드 반영 지점

| 결정 | 버전 | 반영 위치 |
|---|---|---|
| 감정 아이콘 하단 라벨 제거 | v1.2 | `emotion_select_screen.dart` — 화면엔 아이콘만, `Semantics`로만 라벨 유지 |
| 하단 내비 5슬롯 (＋는 FAB) | v1.2 | `app_bottom_nav.dart` — branch 4개 + `centerDocked` FAB |
| 월간 식물 높이 그래프 | v1.2 | `emotion_plant_chart.dart` — percentage 정규화 후 높이 매핑 |
| 캘린더 히트맵 | v1.2 | `month_calendar_sheet.dart` — `CalendarColorMode.garden` |
| "감정의 계절" 스킵 | v1.2 | `emotion_garden_screen.dart` 연간 탭 내 주석으로 위치만 표시 |
| 사진 첨부 위치 | v1.3 | `scene_input_screen.dart` — 질문 → `PhotoPickerStrip` → 텍스트박스 |
| 빈 상태 = 고정 기본 이미지 | v1.3 | `empty_state.dart`, 6곳에서 `stats.isEmpty` 분기 |
| "아직 수정할게 있어요" | v1.3 | `close_day_screen.dart` — draft reset 없이 `/record/emotion` |
| 키워드 읽기 전용 | v1.3 | `DailyRecord.copyWith`에서 `keywords` 의도적 제외 |
| 상점(재화) 시스템 | v1.3 | `shop/` 전체 |
| 케밥 메뉴 4종 | v1.4 | `record_detail_screen.dart` |
| 톱니바퀴 제거 | v1.4 | 나의 나무·감정 정원 AppBar에 햄버거만 |
| 500/500/30자, 사진 10장 | v1.4 | `AppLimits` 상수로 중앙화 |
| 즐겨찾기 | v1.4 | `isFavorite` + `favorites_screen.dart` |
| 소프트 삭제 | v1.5 | `deletedAt` 필드 + 조회 시 필터링 |
| 수정 시 06~07 스킵 | v1.5 | `gratitude_input_screen.dart` — `draft.isEditing`이면 버튼이 "저장" |
| AI 요약은 감정 정원만 | v1.5 | 홈은 고정 카피 상수, `aiSummary`는 garden 화면에서만 참조 |

### 구조적 선택 두 가지

- **캘린더 위젯 공유**: 나의 나무(기록 유무만, 균일 초록)와 감정 정원(감정 히트맵)이
  정보 밀도는 다르지만 같은 `month_calendar_sheet.dart`를 `CalendarColorMode`로
  파라미터화해 공유합니다.
- **신규/수정 단일 플로우**: `RecordDraft.editingDate`가 null이면 신규, 값이 있으면
  수정 모드. 화면을 두 벌 만들지 않고 03~05를 재사용합니다.

---

## Firebase 연동 시 할 일

1. `flutterfire configure` → `firebase_options.dart` 생성
2. `main.dart`의 `Firebase.initializeApp(...)` 주석 해제
3. `record_providers.dart`의 `recordRepositoryProvider` 한 줄만
   `RecordRepositoryMock()` → `FirestoreRecordRepository(...)`로 교체
4. Firestore Security Rules 작성
   - `keywords` 클라이언트 변경 금지 (v1.3 §3.4)
   - `isFavorite`만 클라이언트 write 허용 (v1.4 §4.3)
   - `wallet.balance` 클라이언트 write 전면 금지 (v1.3 §5)
5. Storage 경로: `users/{uid}/records/{date}/photos/{index}.jpg` (v1.4 §5)
6. Cloud Functions
   - 카카오 Custom Token 발급
   - keywords 추출 **및 수정 시 재추출** (v1.5 §5.1)
   - `aiSummary` 생성 (감정 정원 전용)
   - **삭제·수정 시 treeState/statsPeriodic 재계산** (v1.4 §4.2)
   - 소프트 삭제 항목 영구 삭제 배치 (v1.5 §3)

---

## 코드 내 `// TODO:` 로 남겨둔 미정 사항

- 햄버거 메뉴 전체 IA (`menu_screen.dart`는 잠정 목록)
- 상점 진입 경로 최종 확정 — 현재는 메뉴 경유만 구현
- 재화 명칭·단위·환율, IAP 상품 구성, 아이템 가격 정책
- 구매 아이템 영구 소유 vs 시즌제
- 공유 포맷 (카드형 이미지 vs 텍스트)
- 소프트 삭제 보존 기간, 휴지통 UI 필요 여부
- 수정 화면에서 기존 사진 개별 편집 UI
- `periodTreeLevel` 산정 임계값
- 일러스트 에셋 전반 (나무 단계별, 월별 미니 트리, 감정 식물, Rive 연출)
- 온보딩 2·3페이지 문구
- 기간별 필터 UI, 주/월/연 이동 화살표 로직
