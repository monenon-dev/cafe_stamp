import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';

/// 로그인 실패 이유.
enum AuthError {
  emailInUse('이미 가입된 이메일이에요.'),
  invalidCredentials('이메일 또는 비밀번호가 맞지 않아요.');

  const AuthError(this.message);

  /// 화면에 그대로 보여 줄 안내 문구
  final String message;
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthException(${error.name})';
}

/// 인증 저장소.
///
/// 화면과 상태 관리는 이 인터페이스에만 의존한다. 지금은 기기 안에서 동작하는
/// [LocalAuthRepository]를 쓰고, 서버(Firebase Auth 등)를 붙일 때는 같은 메서드를
/// 구현한 클래스로 바꾸기만 하면 된다.
abstract interface class AuthRepository {
  /// 로그인돼 있는 계정. 없으면 null
  Account? get currentAccount;

  Future<Account> signUp({
    required String name,
    required String email,
    required String password,
    bool marketingAgreed = false,
  });

  Future<Account> signIn({required String email, required String password});

  Future<void> signOut();

  /// 현재 계정을 삭제하고 로그아웃한다.
  Future<void> deleteAccount();
}

/// 기기 안(shared_preferences)에 계정을 저장하는 샘플용 인증 저장소.
///
/// 비밀번호는 원문 대신 계정마다 다른 솔트를 붙인 SHA-256 해시로 저장한다.
/// 실제 서비스에서는 서버 인증을 사용해야 한다.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs, {Random? random})
    : _random = random ?? Random.secure();

  static const accountsKey = 'auth_accounts';
  static const sessionKey = 'auth_session';

  final SharedPreferences _prefs;
  final Random _random;

  /// 저장 형식: { 계정 정보..., salt, passwordHash }
  List<Map<String, dynamic>> _records() {
    final raw = _prefs.getString(accountsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _saveRecords(List<Map<String, dynamic>> records) =>
      _prefs.setString(accountsKey, jsonEncode(records));

  static String _normalize(String email) => email.trim().toLowerCase();

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _randomDigits(int length) =>
      List.generate(length, (_) => _random.nextInt(10)).join();

  String _randomSalt() =>
      base64UrlEncode(List.generate(16, (_) => _random.nextInt(256)));

  @override
  Account? get currentAccount {
    final id = _prefs.getString(sessionKey);
    if (id == null) return null;
    for (final r in _records()) {
      if (r['id'] == id) return Account.fromJson(r);
    }
    return null;
  }

  @override
  Future<Account> signUp({
    required String name,
    required String email,
    required String password,
    bool marketingAgreed = false,
  }) async {
    final normalized = _normalize(email);
    final records = _records();
    if (records.any((r) => r['email'] == normalized)) {
      throw const AuthException(AuthError.emailInUse);
    }

    final account = Account(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}-${_randomDigits(4)}',
      name: name.trim(),
      email: normalized,
      memberId: _randomDigits(8),
      createdAt: DateTime.now(),
      marketingAgreed: marketingAgreed,
    );
    final salt = _randomSalt();
    records.add({
      ...account.toJson(),
      'salt': salt,
      'passwordHash': _hash(salt, password),
    });
    await _saveRecords(records);
    await _prefs.setString(sessionKey, account.id);
    return account;
  }

  @override
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = _normalize(email);
    for (final r in _records()) {
      if (r['email'] != normalized) continue;
      if (r['passwordHash'] != _hash(r['salt'] as String, password)) break;
      await _prefs.setString(sessionKey, r['id'] as String);
      return Account.fromJson(r);
    }
    // 이메일이 없는지 비밀번호가 틀렸는지는 구분해서 알려 주지 않는다.
    throw const AuthException(AuthError.invalidCredentials);
  }

  @override
  Future<void> signOut() => _prefs.remove(sessionKey);

  @override
  Future<void> deleteAccount() async {
    final id = _prefs.getString(sessionKey);
    if (id == null) return;
    final records = _records()..removeWhere((r) => r['id'] == id);
    await _saveRecords(records);
    await signOut();
  }
}
