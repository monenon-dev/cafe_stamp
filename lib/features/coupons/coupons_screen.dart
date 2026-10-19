import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/coupon.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/state/coupon_notifier.dart';
import '../../widgets/titled_page.dart';
import 'widgets/coupon_tile.dart';

/// 쿠폰함 탭: 사용 가능 / 사용 완료 / 만료.
class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  static const _tabs = [
    (CouponStatus.available, '사용 가능'),
    (CouponStatus.used, '사용 완료'),
    (CouponStatus.expired, '만료'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableCount = ref.watch(availableCouponsProvider).length;

    return DefaultTabController(
      length: _tabs.length,
      child: TitledPage(
        title: '쿠폰함',
        bottom: TabBar(
          tabs: [
            for (final (status, label) in _tabs)
              Tab(
                text: status == CouponStatus.available && availableCount > 0
                    ? '$label $availableCount'
                    : label,
              ),
          ],
        ),
        body: TabBarView(
          children: [
            for (final (status, _) in _tabs) _CouponList(status: status),
          ],
        ),
      ),
    );
  }
}

class _CouponList extends ConsumerWidget {
  const _CouponList({required this.status});

  final CouponStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(couponsByStatusProvider(status));
    final now = ref.watch(clockProvider)();

    if (coupons.isEmpty) return _EmptyCoupons(status: status);

    return ListView.separated(
      padding: AppSpacing.page.copyWith(top: AppSpacing.md),
      itemCount: coupons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => CouponTile(
        coupon: coupons[i],
        now: now,
        onTap: () => context.go(AppRoutes.couponDetail(coupons[i].id)),
      ),
    );
  }
}

class _EmptyCoupons extends StatelessWidget {
  const _EmptyCoupons({required this.status});

  final CouponStatus status;

  (IconData, String, String) get _content => switch (status) {
    CouponStatus.available => (
      Icons.confirmation_number_outlined,
      '사용할 수 있는 쿠폰이 없어요',
      '스탬프 10개를 모으면 무료 음료 쿠폰을 드려요.',
    ),
    CouponStatus.used => (
      Icons.history_rounded,
      '아직 사용한 쿠폰이 없어요',
      '쿠폰을 사용하면 이곳에 기록이 남아요.',
    ),
    CouponStatus.expired => (
      Icons.event_busy_outlined,
      '만료된 쿠폰이 없어요',
      '유효기간이 지난 쿠폰은 이곳으로 옮겨져요.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (icon, title, message) = _content;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
