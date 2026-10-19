import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/state/profile_stats.dart';

/// 누적 스탬프 · 받은 쿠폰 · 사용한 쿠폰.
class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('누적 스탬프', '${stats.totalStamps}', '개'),
      ('받은 쿠폰', '${stats.receivedCoupons}', '장'),
      ('사용한 쿠폰', '${stats.usedCoupons}', '장'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const VerticalDivider(width: 1),
                Expanded(
                  child: _StatItem(
                    label: items[i].$1,
                    value: items[i].$2,
                    unit: items[i].$3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$label $value$unit',
      excludeSemantics: true,
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
                TextSpan(text: unit, style: textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
