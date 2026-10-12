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
  await _waitForAuthState();

  runApp(const ProviderScope(child: RestreeApp()));
}

/// 저장된 로그인 상태가 복원될 때까지 기다린다.
///
/// 웹은 저장된 로그인 정보를 비동기로 복원해서, 이걸 기다리지 않으면 이미 로그인한
/// 사용자도 잠깐 "로그아웃 상태"로 보여 로그인 화면으로 보내질 수 있다.
/// 로그인이 안 돼 있으면 여기서 로그인시키지 않고, 라우터(app_router.dart)가
/// 온보딩/로그인 화면으로 안내한다.
Future<void> _waitForAuthState() async {
  await FirebaseAuth.instance.authStateChanges().first;
}
