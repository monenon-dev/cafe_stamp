import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/app.dart';
import 'package:moa_stamp/core/validation/validators.dart';
import 'package:moa_stamp/data/repositories/auth_repository.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:moa_stamp/data/state/auth_notifier.dart';
import 'package:moa_stamp/data/state/coupon_notifier.dart';
import 'package:moa_stamp/data/state/stamp_notifier.dart';
import 'package:moa_stamp/features/auth/login_screen.dart';
import 'package:moa_stamp/features/home/home_screen.dart';
import 'package:moa_stamp/features/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 16, 14, 30);

  group('입력값 검사', () {
    test('이름·이메일·비밀번호 규칙', () {
      expect(Validators.name('모'), isNotNull);
      expect(Validators.name('모아'), isNull);
      expect(Validators.email('moa@'), isNotNull);
      expect(Validators.email(' moa@cafe.kr '), isNull);
      expect(Validators.newPassword('short1'), '비밀번호는 8자 이상이어야 해요.');
      expect(Validators.newPassword('onlyletters'), '영문과 숫자를 함께 넣어 주세요.');
      expect(Validators.newPassword('coffee1234'), isNull);
      expect(Validators.confirmPassword('a', 'b'), '비밀번호가 서로 달라요.');
    });

    test('이름은 한글로 받고, 이메일·비밀번호에 한글이 들어가면 키보드를 바꾸라고 알려 준다', () {
      expect(Validators.name('김모아'), isNull);
      // 한국어 자판으로 moa@cafe.kr 를 치면 이렇게 들어간다
      expect(Validators.email('ㅡㅐㅁ@ㅊㅁㄹㄷ.ㅏㄱ'), Validators.hangulInEmail);
      expect(Validators.email('모아@카페.kr'), Validators.hangulInEmail);
      expect(Validators.email('moa@cafe'), '이메일 형식이 맞지 않아요.');
      expect(Validators.email('moa.kim@cafe.co.kr'), isNull);
      expect(Validators.newPassword('채ㄹㄹㄷㄷ1234'), Validators.hangulInPassword);
      expect(Validators.requiredPassword('ㅊㅁㄹㄷ'), Validators.hangulInPassword);
    });
  });

  group('LocalAuthRepository', () {
    late SharedPreferences prefs;
    late LocalAuthRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = LocalAuthRepository(prefs);
    });

    test('가입하면 바로 로그인되고, 비밀번호는 원문으로 저장하지 않는다', () async {
      final account = await repo.signUp(
        name: '모아',
        email: 'Moa@Cafe.kr',
        password: 'coffee1234',
      );

      expect(repo.currentAccount?.id, account.id);
      expect(account.email, 'moa@cafe.kr', reason: '이메일은 소문자로 정리');
      expect(account.memberId, matches(RegExp(r'^\d{8}$')));
      expect(
        prefs.getString(LocalAuthRepository.accountsKey),
        isNot(contains('coffee1234')),
      );
    });

    test('같은 이메일로는 다시 가입할 수 없다 (대소문자 무시)', () async {
      await repo.signUp(
        name: '모아',
        email: 'moa@cafe.kr',
        password: 'coffee1234',
      );
      expect(
        () =>
            repo.signUp(name: '다른', email: 'MOA@cafe.kr', password: 'tea12345'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.error,
            'error',
            AuthError.emailInUse,
          ),
        ),
      );
    });

    test('비밀번호가 틀리거나 없는 이메일이면 같은 안내로 거절한다', () async {
      await repo.signUp(
        name: '모아',
        email: 'moa@cafe.kr',
        password: 'coffee1234',
      );
      await repo.signOut();

      for (final (email, password) in [
        ('moa@cafe.kr', 'wrong1234'),
        ('nobody@cafe.kr', 'coffee1234'),
      ]) {
        expect(
          () => repo.signIn(email: email, password: password),
          throwsA(
            isA<AuthException>().having(
              (e) => e.error,
              'error',
              AuthError.invalidCredentials,
            ),
          ),
        );
      }
      expect(repo.currentAccount, isNull);

      final account = await repo.signIn(
        email: 'moa@cafe.kr',
        password: 'coffee1234',
      );
      expect(account.name, '모아');
    });
  });

  group('계정별 데이터', () {
    late ProviderContainer container;

    Future<void> setUpContainer() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
    }

    test('새 회원은 스탬프 0개와 가입 축하 쿠폰으로 시작한다', () async {
      await setUpContainer();
      await container
          .read(authProvider.notifier)
          .signUp(name: '새회원', email: 'new@cafe.kr', password: 'coffee1234');

      expect(container.read(stampProvider).card.count, 0);
      final coupons = container.read(couponsProvider);
      expect(coupons.single.title, '가입 축하 음료 사이즈 업');
    });

    test('다른 계정의 스탬프는 섞이지 않고, 다시 로그인하면 그대로 남아 있다', () async {
      await setUpContainer();
      final auth = container.read(authProvider.notifier);

      await auth.signUp(name: '첫째', email: 'a@cafe.kr', password: 'coffee1234');
      await container.read(stampProvider.notifier).stamp();
      await container.read(stampProvider.notifier).stamp();
      expect(container.read(stampProvider).card.count, 2);

      await auth.signOut();
      await auth.signUp(name: '둘째', email: 'b@cafe.kr', password: 'coffee1234');
      expect(container.read(stampProvider).card.count, 0);

      await auth.signOut();
      await auth.signIn(email: 'a@cafe.kr', password: 'coffee1234');
      expect(container.read(stampProvider).card.count, 2);
    });

    test('데모 계정은 예시 기록으로 시작하고, 두 번째부터는 기록을 이어 쓴다', () async {
      await setUpContainer();
      final auth = container.read(authProvider.notifier);

      await auth.signInDemo();
      expect(container.read(stampProvider).card.count, 7);
      expect(container.read(couponsProvider), hasLength(4));

      await container.read(stampProvider.notifier).stamp();
      await auth.signOut();
      await auth.signInDemo();
      expect(container.read(stampProvider).card.count, 8);
    });

    test('탈퇴하면 계정과 기록이 함께 지워진다', () async {
      await setUpContainer();
      final auth = container.read(authProvider.notifier);
      await auth.signUp(
        name: '탈퇴',
        email: 'bye@cafe.kr',
        password: 'coffee1234',
      );
      final id = container.read(authProvider)!.id;
      await container.read(stampProvider.notifier).stamp();

      await auth.deleteAccount();

      final prefs = container.read(sharedPreferencesProvider);
      expect(container.read(authProvider), isNull);
      expect(prefs.getKeys().where((k) => k.startsWith(id)), isEmpty);
      expect(
        () => auth.signIn(email: 'bye@cafe.kr', password: 'coffee1234'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('로그인·회원가입 화면', () {
    Future<void> pumpLoggedOut(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({onboardingDoneKey: true});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => now),
          ],
          child: const MoaStampApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('로그인하지 않았으면 로그인 화면이 먼저 나온다', (tester) async {
      await pumpLoggedOut(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('빈 칸과 틀린 비밀번호에 안내를 보여 준다', (tester) async {
      await pumpLoggedOut(tester);

      await tester.tap(find.widgetWithText(FilledButton, '로그인'));
      await tester.pumpAndSettle();
      expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
      expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);

      await tester.enterText(field('이메일'), 'nobody@cafe.kr');
      await tester.enterText(field('비밀번호'), 'wrong1234');
      await tester.tap(find.widgetWithText(FilledButton, '로그인'));
      await tester.pumpAndSettle();
      expect(find.text(AuthError.invalidCredentials.message), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('회원가입은 필수 약관 동의가 있어야 끝나고, 가입하면 홈으로 간다', (tester) async {
      await pumpLoggedOut(tester);
      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();

      await tester.enterText(field('이름'), '모아');
      await tester.enterText(field('이메일'), 'moa@cafe.kr');
      await tester.enterText(field('비밀번호'), 'coffee1234');
      await tester.enterText(field('비밀번호 확인'), 'coffee1234');

      // 약관 동의 없이 가입 시도
      await tester.tap(find.text('가입하기'));
      await tester.pumpAndSettle();
      expect(find.text('필수 약관에 동의해 주세요.'), findsOneWidget);

      await tester.ensureVisible(find.text('약관에 모두 동의해요'));
      await tester.tap(find.text('약관에 모두 동의해요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('가입하기'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('가입을 환영해요! 쿠폰함에 가입 축하 쿠폰을 넣어 드렸어요.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('한글 이름으로 가입되고, 이메일에 한글이 들어가면 안내한다', (tester) async {
      await pumpLoggedOut(tester);
      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();

      await tester.enterText(field('이름'), '김모아');
      await tester.enterText(field('이메일'), 'ㅡㅐㅁ@ㅊㅁㄹㄷ.ㅏㄱ');
      await tester.enterText(field('비밀번호'), 'coffee1234');
      await tester.enterText(field('비밀번호 확인'), 'coffee1234');
      await tester.ensureVisible(find.text('약관에 모두 동의해요'));
      await tester.tap(find.text('약관에 모두 동의해요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('가입하기'));
      await tester.pumpAndSettle();
      expect(find.text(Validators.hangulInEmail), findsOneWidget);

      await tester.enterText(field('이메일'), 'moa@cafe.kr');
      await tester.tap(find.text('가입하기'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('내 정보'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('김모아님'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('데모 계정으로 둘러보고, 내 정보에서 로그아웃하면 로그인 화면으로 돌아간다', (tester) async {
      await pumpLoggedOut(tester);

      await tester.tap(find.text('데모 계정으로 둘러보기'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('7 / 10'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('내 정보'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('${AuthNotifier.demoName}님'), findsOneWidget);

      // 계정 메뉴는 화면 아래쪽이라 스크롤해서 연다.
      await tester.scrollUntilVisible(find.text('로그아웃'), 300);
      await tester.ensureVisible(find.text('로그아웃'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '로그아웃'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
