// 최종 수정: 2026-10-12
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Google 로그인 시도의 결과.
enum GoogleSignInOutcome {
  /// 새로 로그인했다 (로그인 화면에서 들어온 일반적인 경우).
  signedIn,

  /// 익명(임시) 계정에 Google 계정을 연결했다. uid가 그대로라서 기존 기록이 유지된다.
  linkedAnonymous,

  /// 사용자가 팝업을 닫았다. 오류가 아니므로 조용히 넘어간다.
  cancelled,

  /// 연결하려던 Google 계정이 이미 다른 계정으로 가입돼 있었고, 로그아웃했다.
  /// 로그인 화면에서 Google로 다시 시작하면 그 기존 계정으로 들어간다.
  needsRetry,
}

/// Firebase Auth를 감싼 서비스. 화면은 이 클래스만 통해 로그인한다.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  /// Google로 로그인한다.
  ///
  /// 지금 익명 계정으로 쓰는 중이면 새 계정을 만드는 대신 Google 계정을 **연결**한다.
  /// 그러면 uid가 바뀌지 않아서 익명으로 쓴 기록이 그대로 이어진다.
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    if (!kIsWeb) {
      // TODO: Android/iOS는 google_sign_in 연동 단계에서 추가 (SHA-1 등록 등 별도 설정이 필요)
      throw UnsupportedError('Google 로그인은 아직 웹에서만 지원해요.');
    }

    final provider = GoogleAuthProvider();
    final user = _auth.currentUser;

    try {
      if (user != null && user.isAnonymous) {
        await user.linkWithPopup(provider);
        return GoogleSignInOutcome.linkedAnonymous;
      }
      await _auth.signInWithPopup(provider);
      return GoogleSignInOutcome.signedIn;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        return GoogleSignInOutcome.cancelled;
      }

      // 연결하려는 Google 계정이 이미 가입된 계정이면 연결할 수 없다.
      if (e.code == 'credential-already-in-use') {
        final credential = e.credential;
        if (credential != null) {
          // 그 기존 계정으로 바로 로그인한다. (익명 계정에 있던 기록은 옮겨지지 않는다)
          await _auth.signInWithCredential(credential);
          return GoogleSignInOutcome.signedIn;
        }
        // 오류에 자격 증명이 안 담겨 있으면(플랫폼에 따라 그럴 수 있음) 로그아웃하고
        // 사용자가 로그인 화면에서 한 번 더 누르게 한다. 팝업은 사용자 클릭 직후에만 열려서
        // 여기서 곧바로 다시 열 수 없다.
        await _auth.signOut();
        return GoogleSignInOutcome.needsRetry;
      }
      rethrow;
    }
  }

  /// 개발용: 팝업 없이 익명 계정으로 시작한다. (화면에는 디버그 빌드에서만 노출)
  Future<void> signInAnonymouslyForDev() => _auth.signInAnonymously();

  Future<void> signOut() => _auth.signOut();
}

/// 로그인 오류를 사용자에게 보여줄 한국어 문구로 바꾼다.
String authErrorMessage(Object error) {
  if (error is UnsupportedError) return error.message ?? '지원하지 않는 로그인 방식이에요.';
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'popup-blocked' => '팝업이 차단됐어요. 브라우저의 팝업 차단을 풀고 다시 시도해 주세요.',
      'operation-not-allowed' => 'Firebase 콘솔에서 이 로그인 방법이 아직 켜져 있지 않아요.',
      'unauthorized-domain' => '이 주소는 Firebase의 승인된 도메인에 없어요. (Authentication > 설정 > 승인된 도메인)',
      'network-request-failed' => '네트워크 연결을 확인해 주세요.',
      'account-exists-with-different-credential' => '같은 이메일로 다른 방식의 계정이 이미 있어요.',
      _ => '로그인에 실패했어요. (${error.code})',
    };
  }
  return '로그인에 실패했어요. ($error)';
}
