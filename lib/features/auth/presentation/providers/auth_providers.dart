// 최종 수정: 2026-10-12
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
