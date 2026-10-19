import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/data/models/coupon.dart';
import 'package:moa_stamp/data/models/stamp_card.dart';
import 'package:moa_stamp/data/models/stamp_record.dart';
import 'package:moa_stamp/data/repositories/coupon_repository.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:moa_stamp/data/repositories/stamp_repository.dart';
import 'package:moa_stamp/data/state/coupon_notifier.dart';
import 'package:moa_stamp/data/state/stamp_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 16, 14, 30);
  late SharedPreferences prefs;

  /// [count]개가 찍힌 카드로 시작하는 컨테이너를 만든다.
  Future<ProviderContainer> containerWith(int count) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await StampRepository(prefs).save(
      StampCard(
        count: count,
        history: [
          for (var i = 0; i < count; i++)
            StampRecord(
              id: 'seed-$i',
              stampedAt: now.subtract(Duration(days: i + 1)),
              count: 1,
              memo: '아메리카노 1잔 주문',
            ),
        ],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('적립하면 개수가 1 늘고 이력이 맨 앞에 쌓인다', () async {
    final container = await containerWith(7);

    final result = await container.read(stampProvider.notifier).stamp();

    expect(result, isA<Stamped>());
    final card = container.read(stampProvider).card;
    expect(card.count, 8);
    expect(card.history, hasLength(8));
    expect(card.history.first.stampedAt, now);
    expect(StampRepository(prefs).load().count, 8);
  });

  test('9개에서 적립하면 무료 음료 쿠폰이 발급되고 카드는 0개로 리셋된다', () async {
    final container = await containerWith(9);
    final couponsBefore = container.read(couponsProvider).length;

    final result = await container.read(stampProvider.notifier).stamp();

    expect(result, isA<CouponIssued>());
    final coupon = (result! as CouponIssued).coupon;
    expect(coupon.title, StampNotifier.rewardTitle);
    expect(coupon.statusAt(now), CouponStatus.available);
    expect(coupon.expiresAt, now.add(StampNotifier.rewardValidity));

    final card = container.read(stampProvider).card;
    expect(card.count, 0, reason: '초과분 없이 0개로 리셋');
    expect(card.goal, 10);
    expect(card.history, hasLength(10), reason: '이력은 누적 보관');

    final coupons = container.read(couponsProvider);
    expect(coupons, hasLength(couponsBefore + 1));
    expect(coupons.first.id, coupon.id);

    // 저장소에도 반영됐는지 확인
    expect(StampRepository(prefs).load().count, 0);
    expect(CouponRepository(prefs).loadAll().first.id, coupon.id);
  });

  test('처리 중에 다시 누르면 무시되어 한 번만 적립된다', () async {
    final container = await containerWith(3);
    final notifier = container.read(stampProvider.notifier);

    final first = notifier.stamp();
    expect(container.read(stampProvider).isSaving, isTrue);
    final second = notifier.stamp();
    final third = notifier.stamp();

    expect(await first, isA<Stamped>());
    expect(await second, isNull);
    expect(await third, isNull);

    final state = container.read(stampProvider);
    expect(state.card.count, 4);
    expect(state.card.history, hasLength(4));
    expect(state.isSaving, isFalse);
  });

  test('9개에서 연타해도 쿠폰은 1장만 발급된다', () async {
    final container = await containerWith(9);
    final notifier = container.read(stampProvider.notifier);

    final results = await Future.wait([
      notifier.stamp(),
      notifier.stamp(),
      notifier.stamp(),
    ]);

    expect(results.whereType<CouponIssued>(), hasLength(1));
    expect(results.where((r) => r == null), hasLength(2));
    expect(container.read(couponsProvider), hasLength(1));
    expect(container.read(stampProvider).card.count, 0);
  });
}
