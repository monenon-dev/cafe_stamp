import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/app.dart';
import 'package:moa_stamp/data/models/coupon.dart';
import 'package:moa_stamp/data/repositories/coupon_repository.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:moa_stamp/data/state/coupon_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/signed_in.dart';

void main() {
  final now = DateTime(2026, 10, 16, 14, 30);

  Future<ProviderContainer> seededContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await seedMockDataIfFirstLaunch(prefs, now: now);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('쿠폰 상태', () {
    test('상태별로 나누고 사용 가능 쿠폰은 만료 임박순으로 정렬한다', () async {
      final c = await seededContainer();

      final available = c.read(couponsByStatusProvider(CouponStatus.available));
      expect(available.map((e) => e.id), [
        'coupon-cake-3000',
        'coupon-free-drink-02',
      ]);
      expect(c.read(couponsByStatusProvider(CouponStatus.used)), hasLength(1));
      expect(
        c.read(couponsByStatusProvider(CouponStatus.expired)),
        hasLength(1),
      );
    });

    test('사용하면 사용 완료로 옮겨지고 저장된다', () async {
      final c = await seededContainer();
      final notifier = c.read(couponsProvider.notifier);

      expect(await notifier.use('coupon-cake-3000'), isTrue);

      final used = c.read(couponByIdProvider('coupon-cake-3000'))!;
      expect(used.usedAt, now);
      expect(c.read(availableCouponsProvider), hasLength(1));
      final saved = CouponRepository(
        c.read(sharedPreferencesProvider),
      ).loadAll().firstWhere((e) => e.id == 'coupon-cake-3000');
      expect(saved.usedAt, now);
    });

    test('이미 사용했거나 만료된 쿠폰, 동시 요청은 처리하지 않는다', () async {
      final c = await seededContainer();
      final notifier = c.read(couponsProvider.notifier);

      expect(
        await notifier.use('coupon-free-drink-01'),
        isFalse,
        reason: '사용 완료',
      );
      expect(await notifier.use('coupon-size-up'), isFalse, reason: '만료');
      expect(await notifier.use('no-such-coupon'), isFalse);

      final results = await Future.wait([
        notifier.use('coupon-free-drink-02'),
        notifier.use('coupon-free-drink-02'),
      ]);
      expect(results.where((r) => r), hasLength(1));
    });

    test('쿠폰 번호는 id마다 항상 같은 값이다', () {
      Coupon make(String id) => Coupon(
        id: id,
        title: '',
        description: '',
        issuedAt: now,
        expiresAt: now,
      );
      expect(make('a').displayCode, make('a').displayCode);
      expect(make('a').displayCode, isNot(make('b').displayCode));
      expect(make('a').displayCode, matches(RegExp(r'^MOA \d{4} \d{4}$')));
    });
  });

  group('쿠폰함 화면', () {
    Future<void> openCoupons(WidgetTester tester, {bool seeded = true}) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final prefs = (await signedInPrefs(seeded: seeded, now: now)).prefs;

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
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('쿠폰함'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('탭별 목록과 빈 상태를 보여 준다', (tester) async {
      await openCoupons(tester);

      expect(find.text('사용 가능 2'), findsOneWidget);
      expect(find.text('조각 케이크 3,000원 할인'), findsOneWidget);

      await tester.tap(find.text('만료'));
      await tester.pumpAndSettle();
      expect(find.text('음료 사이즈 업'), findsOneWidget);
    });

    testWidgets('쿠폰이 없으면 탭마다 안내 문구를 보여 준다', (tester) async {
      await openCoupons(tester, seeded: false);

      expect(find.text('사용할 수 있는 쿠폰이 없어요'), findsOneWidget);
      await tester.tap(find.text('사용 완료'));
      await tester.pumpAndSettle();
      expect(find.text('아직 사용한 쿠폰이 없어요'), findsOneWidget);
    });

    testWidgets('상세에서 확인 후 사용하면 사용 완료로 바뀐다', (tester) async {
      await openCoupons(tester);

      await tester.tap(find.text('조각 케이크 3,000원 할인'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, '쿠폰 상세'), findsOneWidget);
      expect(find.textContaining('MOA '), findsOneWidget);

      // 취소하면 아무 일도 없다
      await tester.tap(find.text('쿠폰 사용하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('쿠폰 사용하기'), findsOneWidget);

      await tester.tap(find.text('쿠폰 사용하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '사용하기'));
      await tester.pumpAndSettle();

      expect(find.text('쿠폰을 사용했어요. 맛있게 드세요!'), findsOneWidget);
      expect(find.text('이미 사용한 쿠폰이에요'), findsOneWidget);
      expect(find.text('사용 완료'), findsOneWidget);

      // 목록으로 돌아가면 사용 가능 개수가 줄어 있다
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('사용 가능 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('만료된 쿠폰은 사용 버튼이 비활성화된다', (tester) async {
      await openCoupons(tester);

      await tester.tap(find.text('만료'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('음료 사이즈 업'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '유효기간이 지난 쿠폰이에요'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('기간 만료'), findsOneWidget);
    });
  });
}
