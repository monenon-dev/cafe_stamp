import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mock/mock_data.dart';
import '../models/coupon.dart';
import '../state/auth_notifier.dart';
import 'auth_repository.dart';
import 'coupon_repository.dart';
import 'scoped_key.dart';
import 'stamp_repository.dart';

/// main()에서 초기화한 인스턴스로 override 해서 사용한다.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// 인증 저장소. 서버 인증으로 바꿀 때는 이 provider만 교체한다.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(ref.watch(sharedPreferencesProvider)),
);

/// 지금 데이터를 읽고 쓰는 범위(로그인한 계정 id). 로그인 전이면 빈 문자열.
final dataScopeProvider = Provider<String>(
  (ref) => ref.watch(authProvider)?.id ?? '',
);

final stampRepositoryProvider = Provider<StampRepository>(
  (ref) => StampRepository(
    ref.watch(sharedPreferencesProvider),
    scope: ref.watch(dataScopeProvider),
  ),
);

final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepository(
    ref.watch(sharedPreferencesProvider),
    scope: ref.watch(dataScopeProvider),
  ),
);

/// 목 데이터를 넣었는지 기록하는 키 (계정별).
const _mockSeededKey = 'mock_data_seeded';

/// [scope] 계정에 목 데이터를 처음 한 번만 저장한다.
///
/// 플래그가 한 번 기록되면 이후에는 사용자가 바꾼 데이터를 덮어쓰지 않는다.
Future<void> seedMockDataIfFirstLaunch(
  SharedPreferences prefs, {
  String scope = '',
  DateTime? now,
}) async {
  final flag = scopedKey(scope, _mockSeededKey);
  if (prefs.getBool(flag) ?? false) return;

  final at = now ?? DateTime.now();
  await StampRepository(prefs, scope: scope).save(MockData.stampCard(at));
  await CouponRepository(prefs, scope: scope).saveAll(MockData.coupons(at));
  await prefs.setBool(flag, true);
}

/// [scope] 계정의 스탬프·쿠폰을 지우고 목 데이터를 다시 넣는다.
Future<void> restoreMockData(
  SharedPreferences prefs, {
  String scope = '',
  DateTime? now,
}) async {
  await prefs.remove(scopedKey(scope, _mockSeededKey));
  await seedMockDataIfFirstLaunch(prefs, scope: scope, now: now);
}

/// [scope] 계정의 스탬프·쿠폰을 모두 지운다. 목 데이터가 다시 들어가지 않도록
/// 플래그는 남겨 둔다.
Future<void> clearAllData(SharedPreferences prefs, {String scope = ''}) async {
  await prefs.remove(scopedKey(scope, StampRepository.storageKey));
  await prefs.remove(scopedKey(scope, CouponRepository.storageKey));
  await prefs.setBool(scopedKey(scope, _mockSeededKey), true);
}

/// [scope] 계정의 데이터를 흔적 없이 지운다 (회원 탈퇴).
Future<void> deleteScopedData(SharedPreferences prefs, String scope) async {
  await prefs.remove(scopedKey(scope, StampRepository.storageKey));
  await prefs.remove(scopedKey(scope, CouponRepository.storageKey));
  await prefs.remove(scopedKey(scope, _mockSeededKey));
}

/// 새로 가입한 계정에 넣는 가입 축하 쿠폰.
Future<void> giveWelcomeCoupon(
  SharedPreferences prefs, {
  required String scope,
  required DateTime now,
}) async {
  await CouponRepository(prefs, scope: scope).saveAll([
    Coupon(
      id: 'coupon-welcome-${now.microsecondsSinceEpoch}',
      title: '가입 축하 음료 사이즈 업',
      description: '모아 스탬프에 오신 걸 환영해요. 원하는 음료를 한 단계 큰 사이즈로 드려요.',
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 30)),
    ),
  ]);
  // 가입한 계정에는 목 데이터를 넣지 않는다.
  await prefs.setBool(scopedKey(scope, _mockSeededKey), true);
}

/// 현재 시각. 테스트에서 고정된 시각으로 override 한다.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// 온보딩을 끝냈는지 저장하는 키.
const onboardingDoneKey = 'onboarding_done';

/// 로그인 전 기기용 회원 번호 저장 키.
const _memberIdKey = 'member_id';

/// 멤버십 회원 번호 (숫자 8자리).
///
/// 로그인한 계정이 있으면 그 계정의 번호를 쓴다. 없으면(테스트 등) 기기에서 한 번 만들어 저장한다.
final memberIdProvider = Provider<String>((ref) {
  final account = ref.watch(authProvider);
  if (account != null) return account.memberId;

  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getString(_memberIdKey);
  if (saved != null) return saved;

  final random = Random.secure();
  final id = List.generate(8, (_) => random.nextInt(10)).join();
  prefs.setString(_memberIdKey, id);
  return id;
});
