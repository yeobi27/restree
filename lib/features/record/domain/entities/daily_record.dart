import 'package:restree/core/constants/emotion.dart';

/// users/{uid}/records/{date} — 문서ID는 date(yyyy-MM-dd) 고정.
/// 설계서 v1.4 §4.1 / v1.5 §3 반영.
class DailyRecord {
  final String date;
  final Emotion emotion;

  /// 최대 500자 (v1.4 정정)
  final String sceneText;

  /// 최대 500자 (v1.4 정정)
  final String gratitudeText;

  /// 최대 30자 (v1.4 정정)
  final String messageToSelf;

  /// AI가 저장 후 비동기로 채우는 읽기 전용 필드 (v1.3 §3.4).
  /// 클라이언트에서 절대 직접 생성·수정하지 않는다.
  final List<String> keywords;

  /// 최대 10장 (v1.4 — 기존 단일 imageUrl에서 리스트로 변경)
  final List<String> imageUrls;

  /// 즐겨찾기 — 사용자가 케밥 메뉴에서 수동 토글 (v1.4 §3.2).
  /// 시스템이 자동 선정하는 highlightRecordIds와는 별개 개념.
  final bool isFavorite;

  /// 소프트 삭제 (v1.5 §3). null이면 정상 레코드.
  final DateTime? deletedAt;

  final String leafType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyRecord({
    required this.date,
    required this.emotion,
    required this.sceneText,
    required this.gratitudeText,
    required this.messageToSelf,
    this.keywords = const [],
    this.imageUrls = const [],
    this.isFavorite = false,
    this.deletedAt,
    required this.leafType,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get hasPhoto => imageUrls.isNotEmpty;

  /// 미리보기 썸네일 — v1.4 §4.1 비고에 따라 첫 번째 사진 사용
  String? get thumbnailUrl => imageUrls.isEmpty ? null : imageUrls.first;

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        date: json['date'] as String,
        emotion: EmotionX.fromKey(json['emotion'] as String),
        sceneText: json['sceneText'] as String? ?? '',
        gratitudeText: json['gratitudeText'] as String? ?? '',
        messageToSelf: json['messageToSelf'] as String? ?? '',
        keywords: (json['keywords'] as List?)?.cast<String>() ?? const [],
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? const [],
        isFavorite: json['isFavorite'] as bool? ?? false,
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        leafType: json['leafType'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'emotion': emotion.name,
        'sceneText': sceneText,
        'gratitudeText': gratitudeText,
        'messageToSelf': messageToSelf,
        'keywords': keywords,
        'imageUrls': imageUrls,
        'isFavorite': isFavorite,
        'deletedAt': deletedAt?.toIso8601String(),
        'leafType': leafType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  DailyRecord copyWith({
    Emotion? emotion,
    String? sceneText,
    String? gratitudeText,
    String? messageToSelf,
    List<String>? imageUrls,
    bool? isFavorite,
    DateTime? deletedAt,
  }) =>
      DailyRecord(
        date: date,
        emotion: emotion ?? this.emotion,
        sceneText: sceneText ?? this.sceneText,
        gratitudeText: gratitudeText ?? this.gratitudeText,
        messageToSelf: messageToSelf ?? this.messageToSelf,
        // keywords는 copyWith로 노출하지 않는다 — 서버(AI)만 갱신 가능
        keywords: keywords,
        imageUrls: imageUrls ?? this.imageUrls,
        isFavorite: isFavorite ?? this.isFavorite,
        deletedAt: deletedAt ?? this.deletedAt,
        leafType: (emotion ?? this.emotion).name,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
