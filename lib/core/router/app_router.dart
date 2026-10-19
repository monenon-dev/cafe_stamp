import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/repository_providers.dart';
import '../../data/state/auth_notifier.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/coupons/coupon_detail_screen.dart';
import '../../features/coupons/coupons_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/membership/membership_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/stamp/stamp_screen.dart';
import '../../widgets/main_tab_shell.dart';

/// 라우트 경로 상수.
abstract final class AppRoutes {
  static const home = '/home';
  static const stamp = '/stamp';
  static const coupons = '/coupons';
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const membership = '/membership';
  static const login = '/login';
  static const signup = '/signup';

  static String couponDetail(String id) => '$coupons/$id';

  /// 멤버십 QR. [demoScan]이면 "직원 스캔 체험하기" 버튼을 함께 보여 준다.
  static String membershipWith({bool demoScan = false}) =>
      demoScan ? '$membership?demo=1' : membership;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  // 로그인·로그아웃하면 redirect를 다시 계산한다.
  final authChanges = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authChanges,
    // 순서: 온보딩 → 로그인 → 앱
    redirect: (context, state) {
      final location = state.matchedLocation;

      final onboarded = prefs.getBool(onboardingDoneKey) ?? false;
      if (!onboarded) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      final loggedIn = ref.read(authProvider) != null;
      final atAuth =
          location == AppRoutes.login || location == AppRoutes.signup;
      if (!loggedIn) return atAuth ? null : AppRoutes.login;
      if (atAuth || location == AppRoutes.onboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // 하단 탭 바를 덮는 전체 화면. 닫으면 결과(bool)를 돌려준다.
      GoRoute(
        path: AppRoutes.membership,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: MembershipScreen(
            allowDemoScan: state.uri.queryParameters['demo'] == '1',
          ),
        ),
      ),
      // 하단 탭 4개. 탭마다 독립된 내비게이션 스택을 유지한다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainTabShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stamp,
                builder: (context, state) => const StampScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.coupons,
                builder: (context, state) => const CouponsScreen(),
                routes: [
                  // 쿠폰 상세. 쿠폰함 탭 안에서 열려 하단 탭 바가 유지된다.
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => CouponDetailScreen(
                      couponId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
