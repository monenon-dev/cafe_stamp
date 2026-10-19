import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../repositories/repository_providers.dart';

/// 로그인 상태. 로그인한 계정, 로그아웃 상태면 null.
///
/// 계정이 바뀌면 이 값을 보는 저장소·스탬프·쿠폰 상태가 모두 새 계정 기준으로 다시 만들어진다.
class AuthNotifier extends Notifier<Account?> {
  /// 데모 계정. 로그인 화면의 "데모 계정으로 둘러보기"에서 쓴다.
  static const demoEmail = 'demo@moastamp.app';
  static const demoPassword = 'moastamp1234';
  static const demoName = '모아';

  @override
  Account? build() => ref.watch(authRepositoryProvider).currentAccount;

  Future<void> signIn({required String email, required String password}) async {
    state = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
  }

  /// 가입 후 바로 로그인하고, 가입 축하 쿠폰을 넣어 준다.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    bool marketingAgreed = false,
  }) async {
    final account = await ref
        .read(authRepositoryProvider)
        .signUp(
          name: name,
          email: email,
          password: password,
          marketingAgreed: marketingAgreed,
        );
    await giveWelcomeCoupon(
      ref.read(sharedPreferencesProvider),
      scope: account.id,
      now: ref.read(clockProvider)(),
    );
    state = account;
  }

  /// 데모 계정으로 로그인한다. 처음이면 계정을 만들고 예시 기록을 넣는다.
  Future<void> signInDemo() async {
    final repo = ref.read(authRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      state = await repo.signIn(email: demoEmail, password: demoPassword);
    } on Exception {
      final account = await repo.signUp(
        name: demoName,
        email: demoEmail,
        password: demoPassword,
      );
      await seedMockDataIfFirstLaunch(
        prefs,
        scope: account.id,
        now: ref.read(clockProvider)(),
      );
      state = account;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }

  /// 계정과 그 계정의 스탬프·쿠폰 기록을 모두 지운다.
  Future<void> deleteAccount() async {
    final id = state?.id;
    await ref.read(authRepositoryProvider).deleteAccount();
    if (id != null) {
      await deleteScopedData(ref.read(sharedPreferencesProvider), id);
    }
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, Account?>(AuthNotifier.new);

/// 화면에 보여 줄 이름. 로그인 전(테스트 등)에는 기본 호칭을 쓴다.
final displayNameProvider = Provider<String>(
  (ref) => ref.watch(authProvider)?.name ?? '모아 회원',
);
