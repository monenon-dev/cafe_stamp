import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/coupon.dart';

/// 스탬프 10개를 채워 쿠폰이 발급됐을 때의 축하 안내.
///
/// "쿠폰함 보기"를 누르면 true를 돌려준다.
class CouponIssuedDialog extends StatelessWidget {
  const CouponIssuedDialog({super.key, required this.coupon});

  final Coupon coupon;

  static Future<bool> show(BuildContext context, Coupon coupon) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => CouponIssuedDialog(coupon: coupon),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: AppSpacing.xxl,
                backgroundColor: colors.tertiaryContainer,
                foregroundColor: colors.tertiary,
                child: const Icon(Icons.celebration_rounded, size: 32),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '스탬프 10개를 모두 모았어요!',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${coupon.title}이 쿠폰함에 들어갔어요.\n'
              '${AppDateFormat.date(coupon.expiresAt)}까지 사용할 수 있어요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '스탬프 카드는 새로 시작돼요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('쿠폰함 보기'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}
