import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/app.dart';
import 'package:moa_stamp/core/format/keep_all.dart';
import 'package:moa_stamp/data/repositories/auth_repository.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:moa_stamp/features/home/home_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/signed_in.dart';

void main() {
  final now = DateTime(2026, 10, 16, 14, 30);

  Future<SharedPreferences> pumpApp(
    WidgetTester tester, {
    required bool onboardingDone,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final prefs = (await signedInPrefs(
      onboardingDone: onboardingDone,
      now: now,
    )).prefs;

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
    return prefs;
  }

  group('온보딩', () {
    testWidgets('첫 실행이면 3장을 넘겨 시작하고, 다음 실행부터는 바로 홈이 열린다', (tester) async {
      final prefs = await pumpApp(tester, onboardingDone: false);

      expect(find.text('한 잔마다 도장 하나'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('10개 모으면 한 잔 무료'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('QR 하나로 적립 끝'), findsOneWidget);

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(prefs.getBool(onboardingDoneKey), isTrue);
    });

    testWidgets('건너뛰기를 누르면 바로 홈으로 간다', (tester) async {
      await pumpApp(tester, onboardingDone: false);

      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('온보딩을 끝냈으면 보여 주지 않는다', (tester) async {
      await pumpApp(tester, onboardingDone: true);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('건너뛰기'), findsNothing);
    });
  });

  group('멤버십·바코드', () {
    testWidgets('홈의 QR 버튼으로 멤버십 QR을 열고, 회원 번호는 유지된다', (tester) async {
      final prefs = await pumpApp(tester, onboardingDone: true);

      await tester.tap(find.byTooltip('멤버십 QR'));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      // 홈에서 열면 데모 적립 버튼은 없다
      expect(find.text('직원 스캔 체험하기'), findsNothing);

      final id = LocalAuthRepository(prefs).currentAccount?.memberId;
      expect(id, matches(RegExp(r'^\d{8}$')));
      expect(
        find.text('회원 번호 ${id!.substring(0, 4)} ${id.substring(4)}'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('사용 가능한 쿠폰 상세에만 바코드가 있다', (tester) async {
      await pumpApp(tester, onboardingDone: true);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('쿠폰함'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('조각 케이크 3,000원 할인'));
      await tester.pumpAndSettle();
      expect(find.byType(BarcodeWidget), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('만료'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('음료 사이즈 업'));
      await tester.pumpAndSettle();
      expect(find.byType(BarcodeWidget), findsNothing);
    });
  });

  test('keepAll은 띄어쓰기 사이에서만 줄이 바뀌도록 글자 사이를 묶는다', () {
    const joiner = '\u2060';
    expect('보여 주세요'.keepAll, '보$joiner여 주$joiner세$joiner요');
    expect('보여 주세요'.keepAll.replaceAll(joiner, ''), '보여 주세요');
  });
}
