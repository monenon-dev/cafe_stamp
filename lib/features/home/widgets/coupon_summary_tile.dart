import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/coupon.dart';

/// 사용 가능한 쿠폰 요약. 만료가 가장 가까운 쿠폰을 함께 보여 준다.
class CouponSummaryTile extends StatelessWidget {
  const CouponSummaryTile({
    super.key,
    required this.available,
    required this.now,
    required this.onTap,
  });

  /// 사용 가능한 쿠폰 (만료 임박순)
  final List<Coupon> available;
  final DateTime now;
  final VoidCallback onTap;

  /// 이 일수 이내로 남으면 만료 임박으로 강조한다.
  static const _expiringSoonDays = 7;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nearest = available.isEmpty ? null : available.first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.tertiaryContainer,
                foregroundColor: colors.onTertiaryContainer,
                child: const Icon(Icons.confirmation_number_rounded),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nearest == null
                          ? '사용할 수 있는 쿠폰이 없어요'
                          : '사용할 수 있는 쿠폰 ${available.length}장',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (nearest == null)
                      Text(
                        '스탬프 10개를 모으면 무료 음료 쿠폰을 드려요.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      _NearestCoupon(coupon: nearest, now: now),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearestCoupon extends StatelessWidget {
  const _NearestCoupon({required this.coupon, required this.now});

  final Coupon coupon;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final days = AppDateFormat.daysUntil(coupon.expiresAt, now: now);
    final expiringSoon = days <= CouponSummaryTile._expiringSoonDays;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${coupon.title} · '),
          TextSpan(
            text: AppDateFormat.dDay(coupon.expiresAt, now: now),
            style: TextStyle(
              color: expiringSoon ? colors.error : colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
    );
  }
}
