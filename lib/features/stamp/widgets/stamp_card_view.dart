import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'stamp_slot.dart';

/// 5칸 × 2줄 스탬프 카드.
class StampCardView extends StatelessWidget {
  const StampCardView({super.key, required this.count, required this.goal});

  final int count;
  final int goal;

  static const _columns = 5;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = (goal - count).clamp(0, goal);
    final rows = (goal / _columns).ceil();

    return Semantics(
      label: '스탬프 $goal개 중 $count개 적립',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'MOA STAMP CARD',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Text(
                      '$goal개 = 음료 1잔',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$count',
                        style: textTheme.displaySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' / $goal',
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                remaining > 0
                    ? '$remaining개 더 모으면 음료 1잔을 무료로 드려요.'
                    : '스탬프를 모두 모았어요! 쿠폰함을 확인해 보세요.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (var row = 0; row < rows; row++) ...[
                if (row > 0) const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (var col = 0; col < _columns; col++) ...[
                      if (col > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _slotAt(row * _columns + col)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotAt(int i) {
    if (i >= goal) return const SizedBox.shrink();
    return StampSlot(index: i + 1, filled: i < count, isReward: i == goal - 1);
  }
}
