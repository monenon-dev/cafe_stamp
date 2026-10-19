import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/app.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';

import 'helpers/signed_in.dart';

void main() {
  // 오후 2시 30분으로 고정
  final now = DateTime(2026, 10, 16, 14, 30);

  Future<void> pumpHome(WidgetTester tester, {required bool seeded}) async {
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
  }

  testWidgets('목 데이터로 진행 요약·쿠폰·최근 적립을 보여 준다', (tester) async {
    await pumpHome(tester, seeded: true);

    expect(find.text('좋은 오후예요'), findsOneWidget);
    expect(find.text('7 / 10'), findsOneWidget);
    expect(find.text('무료 음료까지 3개 남았어요'), findsOneWidget);

    // 사용 가능 2장, 만료 임박(10일 남은 케이크 쿠폰)이 먼저 보인다
    expect(find.text('사용할 수 있는 쿠폰 2장'), findsOneWidget);
    expect(
      find.text('조각 케이크 3,000원 할인 · D-10', findRichText: true),
      findsOneWidget,
    );

    // 이력 5건 중 최신 3건만
    expect(find.text('카페라테 1잔 주문'), findsOneWidget);
    expect(find.text('바닐라 라테 1잔 주문'), findsOneWidget);
    expect(find.text('콜드브루 1잔 주문'), findsNothing);
    expect(find.text('전체 보기'), findsOneWidget);
  });

  testWidgets('데이터가 없으면 첫 이용 안내를 보여 준다', (tester) async {
    await pumpHome(tester, seeded: false);

    expect(find.text('첫 스탬프를 모아 보세요'), findsOneWidget);
    expect(find.text('사용할 수 있는 쿠폰이 없어요'), findsOneWidget);
    expect(find.text('아직 적립 내역이 없어요'), findsOneWidget);
    expect(find.text('전체 보기'), findsNothing);
  });

  testWidgets('버튼과 쿠폰 요약으로 각 탭에 이동한다', (tester) async {
    await pumpHome(tester, seeded: true);

    await tester.tap(find.text('스탬프 적립하러 가기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '적립'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('홈')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('사용할 수 있는 쿠폰 2장'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '쿠폰함'), findsOneWidget);
  });
}
