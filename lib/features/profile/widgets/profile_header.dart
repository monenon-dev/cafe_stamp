import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/state/profile_stats.dart';

/// 회원 등급과 다음 등급까지의 진행 상황.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.stats,
    required this.now,
  });

  final String name;
  final ProfileStats stats;
  final DateTime now;

  String get _since {
    final first = stats.firstActivityAt;
    if (first == null) return '첫 방문을 환영해요';
    final days = -AppDateFormat.daysUntil(first, now: now) + 1;
    return '모아 스탬프와 함께한 지 $days일째예요';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final next = stats.tier.next;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: AppSpacing.xl,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: const Icon(Icons.person_rounded),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$name님', style: textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _since,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.tertiary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    stats.tier.label,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    next == null
                        ? '최고 등급이에요. 늘 찾아 주셔서 고마워요!'
                        : '${next.label}까지 스탬프 ${stats.stampsToNextTier}개 남았어요',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: stats.tierProgress,
                minHeight: AppSpacing.xs,
                color: colors.tertiary,
                backgroundColor: colors.tertiaryContainer,
                semanticsLabel: next == null
                    ? '최고 등급 달성'
                    : '${next.label}까지 ${stats.stampsToNextTier}개 남음',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
