import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/coupon.dart';
import '../../../widgets/ticket.dart';

/// 이 일수 이내로 남은 쿠폰은 만료 임박으로 강조한다.
const expiringSoonDays = 7;

/// 쿠폰 종류별 아이콘.
IconData couponIcon(Coupon coupon) {
  if (coupon.title.contains('음료')) return Icons.local_cafe_rounded;
  if (coupon.title.contains('케이크')) return Icons.cake_rounded;
  return Icons.confirmation_number_rounded;
}

/// 티켓 왼쪽 영역에 크게 보여 줄 혜택 표시. (큰 글씨, 작은 설명)
(String, String) couponBadge(Coupon coupon) {
  final amount = RegExp(r'([\d,]+)원').firstMatch(coupon.title);
  if (amount != null) return (amount.group(1)!, '원 할인');
  if (coupon.title.contains('무료')) return ('FREE', '음료 1잔');
  if (coupon.title.contains('사이즈')) return ('UP', '사이즈');
  return ('쿠폰', '혜택');
}

/// 혜택 종류별 색. 무료 음료는 주색(캐러멜), 그 밖의 혜택은 같은 계열의 진한 에스프레소.
({Color background, Color foreground}) couponColors(
  ColorScheme colors,
  Coupon coupon, {
  required bool active,
}) {
  if (!active) {
    return (
      background: colors.surfaceContainerHighest,
      foreground: colors.onSurfaceVariant,
    );
  }
  return coupon.title.contains('무료')
      ? (background: colors.primary, foreground: colors.onPrimary)
      : (background: colors.tertiary, foreground: colors.onTertiary);
}

/// 쿠폰함 목록의 쿠폰 1장. 왼쪽 혜택 영역과 오른쪽 내용이 절취선으로 나뉜 티켓 모양.
class CouponTile extends StatelessWidget {
  const CouponTile({
    super.key,
    required this.coupon,
    required this.now,
    required this.onTap,
  });

  final Coupon coupon;
  final DateTime now;
  final VoidCallback onTap;

  /// 왼쪽 혜택 영역 너비
  static const _stubWidth = 92.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = coupon.statusAt(now) == CouponStatus.available;
    final stub = couponColors(colors, coupon, active: active);
    final (value, caption) = couponBadge(coupon);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: const TicketShapeBorder(
        splitAxis: Axis.vertical,
        splitOffset: _stubWidth,
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: stub.background,
                child: SizedBox(
                  width: _stubWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Text(
                            value,
                            style: textTheme.titleLarge?.copyWith(
                              color: stub.foreground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        caption,
                        style: textTheme.labelSmall?.copyWith(
                          color: stub.foreground.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DashedLine(axis: Axis.vertical, color: colors.outlineVariant),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: active ? null : colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        coupon.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      CouponStatusLine(coupon: coupon, now: now),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "2027년 1월 14일까지 · D-75", "10월 1일 14:30 사용", "2026년 10월 6일 만료"
class CouponStatusLine extends StatelessWidget {
  const CouponStatusLine({super.key, required this.coupon, required this.now});

  final Coupon coupon;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    switch (coupon.statusAt(now)) {
      case CouponStatus.available:
        final days = AppDateFormat.daysUntil(coupon.expiresAt, now: now);
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${AppDateFormat.date(coupon.expiresAt)}까지 · '),
              TextSpan(
                text: AppDateFormat.dDay(coupon.expiresAt, now: now),
                style: TextStyle(
                  color: days <= expiringSoonDays
                      ? colors.error
                      : colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: style,
        );
      case CouponStatus.used:
        return Text(
          '${AppDateFormat.dateTime(coupon.usedAt!, now: now)} 사용',
          style: style,
        );
      case CouponStatus.expired:
        return Text('${AppDateFormat.date(coupon.expiresAt)} 만료', style: style);
    }
  }
}
