import 'package:moa_stamp/data/repositories/auth_repository.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testEmail = 'tester@moastamp.app';
const testPassword = 'moastamp1234';

/// 온보딩을 마치고 테스트 계정으로 로그인한 상태의 저장소를 만든다.
///
/// [seeded]면 그 계정에 예시 기록(스탬프 7개, 쿠폰 4장)을 넣는다.
/// 돌려주는 scope는 계정 id로, 계정별 저장소를 직접 확인할 때 쓴다.
Future<({SharedPreferences prefs, String scope})> signedInPrefs({
  bool seeded = true,
  bool onboardingDone = true,
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues({onboardingDoneKey: onboardingDone});
  final prefs = await SharedPreferences.getInstance();
  final account = await LocalAuthRepository(
    prefs,
  ).signUp(name: '테스터', email: testEmail, password: testPassword);
  if (seeded) {
    await seedMockDataIfFirstLaunch(prefs, scope: account.id, now: now);
  }
  return (prefs: prefs, scope: account.id);
}
