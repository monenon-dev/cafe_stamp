import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/app.dart';
import 'package:moa_stamp/features/coupons/coupons_screen.dart';
import 'package:moa_stamp/features/home/home_screen.dart';
import 'package:moa_stamp/features/profile/profile_screen.dart';
import 'package:moa_stamp/features/stamp/stamp_screen.dart';
import 'package:moa_stamp/data/models/stamp_card.dart';
import 'package:moa_stamp/data/repositories/coupon_repository.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:moa_stamp/data/repositories/stamp_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/signed_in.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({onboardingDoneKey: true}),
  );

  test('목 데이터는 첫 실행에만 저장된다', () async {
    final prefs = await SharedPreferences.getInstance();
    await seedMockDataIfFirstLaunch(prefs);

    final stamps = StampRepository(prefs);
    final coupons = CouponRepository(prefs);
    expect(stamps.load().count, 7);
    expect(stamps.load().goal, StampCard.defaultGoal);
    expect(coupons.loadAll(), hasLength(4));

    // 사용자가 데이터를 바꾼 뒤 다시 실행해도 덮어쓰지 않는다.
    await stamps.save(const StampCard(count: 2));
    await seedMockDataIfFirstLaunch(prefs);
    expect(stamps.load().count, 2);
  });

  testWidgets('하단 탭 4개로 화면을 전환한다', (tester) async {
    final prefs = (await signedInPrefs()).prefs;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MoaStampApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);

    // (탭 이름, 탭 순서, 열리는 화면)
    const tabs = [
      ('적립', 1, StampScreen),
      ('쿠폰함', 2, CouponsScreen),
      ('내 정보', 3, ProfileScreen),
      ('홈', 0, HomeScreen),
    ];
    for (final (label, index, screen) in tabs) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, index);
    }
  });
}
