// 최종 수정: 2026-10-19
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restree/core/constants/app_config.dart';
import 'package:restree/features/auth/data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 로그인한 계정의 uid. 로그인·로그아웃·다른 계정으로 전환할 때만 값이 바뀐다.
///
/// 저장소(recordRepositoryProvider)가 이 값을 지켜보다가 계정이 바뀌면 새로 만들어진다.
/// (이전 사용자의 데이터가 다음 사용자에게 보이는 일을 막기 위해서다)
final authUidProvider = StreamProvider<String?>(
  (ref) => FirebaseAuth.instance.authStateChanges().map((user) => user?.uid),
);

/// 계정 정보. 익명 계정에 Google을 연결하는 것처럼 uid는 그대로인데 내용이 바뀌는 경우도
/// 감지해야 해서 authStateChanges가 아니라 userChanges를 쓴다. 메뉴의 계정 표시용이다.
final authUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.userChanges(),
);

/// 계정을 만든 날(KST, 날짜만). 통계 기간 이동에서 이보다 이전 기간으로는 못 가게 하는 기준이다.
///
/// 일기는 항상 "오늘" 날짜로만 쓸 수 있으므로, 계정을 만들기 전 기간에는 기록이 있을 수 없다.
/// 익명 계정에 Google을 연결한 경우에는 익명 계정을 처음 만든 날이 기준이 된다(uid가 같으므로).
/// 계정이 바뀌면 다시 계산되도록 uid 변화를 지켜본다.
final accountStartDateProvider = Provider<DateTime?>((ref) {
  if (kUseMockData) return DateTime(2026, 1, 1); // Mock 데이터는 2026년 전체를 보여준다
  ref.watch(authUidProvider.select((a) => a.valueOrNull ?? FirebaseAuth.instance.currentUser?.uid));
  final created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
  if (created == null) return null;
  final kst = created.toUtc().add(const Duration(hours: 9));
  return DateTime(kst.year, kst.month, kst.day);
});
