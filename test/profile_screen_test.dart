import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/app.dart';
import 'package:moa_stamp/data/repositories/repository_providers.dart';
import 'package:moa_stamp/data/state/profile_stats.dart';
import 'package:moa_stamp/data/state/stamp_notifier.dart';

import 'helpers/signed_in.dart';

void main() {
  final now = DateTime(2026, 10, 16, 14, 30);

  test('누적 스탬프에 따라 등급이 정해진다', () {
    expect(MemberTier.of(0), MemberTier.sprout);
    expect(MemberTier.of(9), MemberTier.sprout);
    expect(MemberTier.of(10), MemberTier.regular);
    expect(MemberTier.of(45), MemberTier.devoted);
    expect(MemberTier.devoted.next, isNull);
  });

  group('내 정보 화면', () {
    late ProviderContainer container;
    late String scope;

    Future<void> openProfile(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final signedIn = await signedInPrefs(now: now);
      final prefs = signedIn.prefs;
      scope = signedIn.scope;

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MoaStampApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('내 정보'),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// 통계 항목 [label] 위에 표시된 값 (예: "7개")
    String stat(String label) {
      final column = find.ancestor(
        of: find.text(label),
        matching: find.byType(Column),
      );
      final value = find.descendant(
        of: column.first,
        matching: find.byType(RichText),
      );
      return (value.evaluate().first.widget as RichText).text.toPlainText();
    }

    Future<void> confirm(
      WidgetTester tester,
      String menu,
      String action,
    ) async {
      await tester.ensureVisible(find.text(menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(menu));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, action));
      await tester.pumpAndSettle();
      // 결과를 확인할 수 있도록 맨 위로 돌아간다.
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pumpAndSettle();
    }

    testWidgets('목 데이터 기준 등급과 통계를 보여 준다', (tester) async {
      await openProfile(tester);

      // 가장 오래된 기록은 60일 전에 받은 쿠폰
      expect(find.text('모아 스탬프와 함께한 지 61일째예요'), findsOneWidget);
      expect(find.text('새싹 회원'), findsOneWidget);
      expect(find.text('단골 회원까지 스탬프 3개 남았어요'), findsOneWidget);
      expect(stat('누적 스탬프'), '7개');
      expect(stat('받은 쿠폰'), '4장');
      expect(stat('사용한 쿠폰'), '1장');
    });

    testWidgets('모든 기록을 지우면 빈 상태가 되고, 샘플 데이터로 되돌릴 수 있다', (tester) async {
      await openProfile(tester);

      await confirm(tester, '모든 기록 지우기', '모두 지우기');
      expect(find.text('모든 기록을 지웠어요.'), findsOneWidget);
      expect(find.text('첫 방문을 환영해요'), findsOneWidget);
      expect(stat('누적 스탬프'), '0개');
      expect(container.read(stampProvider).card.count, 0);

      await confirm(tester, '샘플 데이터로 되돌리기', '되돌리기');
      expect(find.text('샘플 데이터로 되돌렸어요.'), findsOneWidget);
      expect(stat('누적 스탬프'), '7개');
      expect(container.read(stampProvider).card.count, 7);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('지운 기록은 다시 실행해도 목 데이터로 채워지지 않는다', (tester) async {
      await openProfile(tester);
      await confirm(tester, '모든 기록 지우기', '모두 지우기');

      final prefs = container.read(sharedPreferencesProvider);
      await seedMockDataIfFirstLaunch(prefs, scope: scope, now: now);
      expect(prefs.getString('$scope.stamp_card'), isNull);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('오픈소스 라이선스 화면을 연다', (tester) async {
      await openProfile(tester);

      await tester.tap(find.text('오픈소스 라이선스'));
      await tester.pumpAndSettle();
      expect(find.text('모아 스탬프'), findsWidgets);
    });
  });
}
