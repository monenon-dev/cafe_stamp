import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/stamp_card.dart';

/// 홈 상단의 스탬프 진행 요약 카드.
class StampSummaryCard extends StatelessWidget {
  const StampSummaryCard({
    super.key,
    required this.card,
    required this.onStampTap,
  });

  final StampCard card;
  final VoidCallback onStampTap;

  String get _message {
    if (card.count == 0 && card.history.isEmpty) {
      return '첫 스탬프를 모아 보세요';
    }
    if (card.count == 0) return '새 스탬프 카드가 시작됐어요';
    return '무료 음료까지 ${card.remaining}개 남았어요';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.local_cafe_rounded, color: colors.secondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '내 스탬프',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.onTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${card.count} / ${card.goal}',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _message,
              style: textTheme.headlineSmall?.copyWith(
                color: colors.onTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: card.progress,
                minHeight: AppSpacing.xs,
                color: colors.secondary,
                backgroundColor: colors.onTertiary.withValues(alpha: 0.15),
                semanticsLabel: '스탬프 ${card.goal}개 중 ${card.count}개',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onStampTap,
              style: FilledButton.styleFrom(
                backgroundColor: colors.tertiaryContainer,
                foregroundColor: colors.onTertiaryContainer,
              ),
              child: const Text('스탬프 적립하러 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
