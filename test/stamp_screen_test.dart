import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/app.dart';
import 'package:moa_stamp/data/models/stamp_card.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:moa_stamp/data/repositories/stamp_repository.dart';
import 'package:moa_stamp/features/stamp/widgets/stamp_slot.dart';

import 'helpers/signed_in.dart';

void main() {
  Future<void> openStampTab(WidgetTester tester, {required int count}) async {
    // 휴대폰 크기(390×844) 화면에서 검증한다.
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final (:prefs, :scope) = await signedInPrefs(seeded: false);
    await StampRepository(prefs, scope: scope).save(StampCard(count: count));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MoaStampApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('적립'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 멤버십 QR을 열고 "직원 스캔 체험하기"로 적립한다.
  Future<void> stampViaQr(WidgetTester tester) async {
    await tester.tap(find.text('QR 보여 주고 적립하기'));
    await tester.pumpAndSettle();
    expect(find.text('MOA MEMBERSHIP'), findsOneWidget);
    await tester.tap(find.text('직원 스캔 체험하기'));
    await tester.pumpAndSettle();
  }

  int filledSlots(WidgetTester tester) => tester
      .widgetList<StampSlot>(find.byType(StampSlot))
      .where((s) => s.filled)
      .length;

  testWidgets('이력이 없으면 빈 상태 문구를 보여 준다', (tester) async {
    await openStampTab(tester, count: 0);

    expect(find.byType(StampSlot), findsNWidgets(10));
    expect(find.text('아직 적립 내역이 없어요'), findsOneWidget);
  });

  testWidgets('적립하면 칸이 채워지고 성공 안내가 뜬다', (tester) async {
    await openStampTab(tester, count: 0);

    await stampViaQr(tester);

    expect(filledSlots(tester), 1);
    expect(find.text('스탬프가 적립됐어요. 무료 음료까지 9개 남았어요.'), findsOneWidget);
    expect(find.text('매장 방문 적립'), findsOneWidget);

    // 스낵바 타이머 정리
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('10번째 스탬프를 찍으면 축하 안내 후 카드가 리셋된다', (tester) async {
    await openStampTab(tester, count: 9);

    await stampViaQr(tester);

    expect(find.text('스탬프 10개를 모두 모았어요!'), findsOneWidget);
    expect(filledSlots(tester), 10, reason: '안내가 떠 있는 동안은 가득 찬 카드');

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(filledSlots(tester), 0);
  });
}
