import 'package:flutter/material.dart';

/// 목업 스크린샷(시작화면/홈/나의나무/감정정원/아카이브)에서 추출한 팔레트.
/// TODO: 정식 디자인 시스템 문서가 나오면 토큰명과 함께 재정리 필요.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFAF8F2); // 앱 전역 배경 (따뜻한 크림)
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF4F2EC); // 기록 미리보기 카드 배경

  static const primary = Color(0xFF3F6B4F); // 올리브 그린 — 버튼, 강조 텍스트
  static const primaryLight = Color(0xFF6B9E78);
  static const brandGold = Color(0xFF6B5518); // "RESTREE" 워드마크

  /// 하루 닫기(06~07) 암전 화면
  static const nightBackground = Color(0xFF22392E);
  static const nightAccent = Color(0xFFC8DC8E);

  static const textPrimary = Color(0xFF2B2B2B);
  static const textSecondary = Color(0xFF8A8A8A);
  static const divider = Color(0xFFE8E5DD);

  static const leafFilled = Color(0xFFAFC79B); // 나의 나무 캘린더 — 기록 있는 날
  static const leafEmpty = Color(0xFFEDEAE2); // 기록 없는 날
  static const soil = Color(0xFF9C7B52); // 감정 정원 흙 라인
}
