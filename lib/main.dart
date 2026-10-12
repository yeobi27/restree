// 최종 수정: 2026-10-12
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:restree/app.dart';
import 'package:restree/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ensureSignedIn();

  runApp(const ProviderScope(child: RestreeApp()));
}

/// 개발 단계: 익명 로그인으로 uid를 확보한다.
///
/// 웹은 저장된 로그인 상태를 비동기로 복원하므로 currentUser를 바로 보지 않고
/// authStateChanges의 첫 이벤트를 기다린다. (안 그러면 새로고침할 때마다 새 익명 계정이
/// 만들어져서 기록이 "사라진 것처럼" 보인다.)
///
/// 여기서 [firebase_auth/operation-not-allowed] 에러가 나면 Firebase 콘솔
/// Authentication > 로그인 방법에서 '익명'을 사용 설정하지 않은 것이다.
///
/// TODO: Google/카카오/Apple 로그인을 붙일 때 익명 계정을 linkWithCredential으로
/// 승격시키면 익명 상태에서 쓴 기록을 그대로 이어받을 수 있다.
Future<void> _ensureSignedIn() async {
  final auth = FirebaseAuth.instance;
  final user = await auth.authStateChanges().first;
  if (user == null) {
    await auth.signInAnonymously();
  }
}
