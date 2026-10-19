import 'package:flutter/material.dart';

import '../core/format/app_date_format.dart';
import '../core/theme/app_spacing.dart';
import '../data/models/stamp_record.dart';

/// 적립 이력 목록 (최신순). 이력이 없으면 빈 상태 안내를 보여 준다.
class StampHistoryList extends StatelessWidget {
  const StampHistoryList({super.key, required this.history, this.limit});

  final List<StampRecord> history;

  /// 최대 표시 개수. null이면 전부 보여 준다.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const _EmptyHistory();

    final sorted = [...history]
      ..sort((a, b) => b.stampedAt.compareTo(a.stampedAt));
    final visible = limit == null ? sorted : sorted.take(limit!).toList();
    final now = DateTime.now();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
            _HistoryTile(record: visible[i], now: now),
          ],
        ],
      ),
    );
  }
}

/// 적립 메모로 고르는 음료 아이콘.
IconData _drinkIcon(String memo) {
  if (memo.contains('콜드브루') || memo.contains('아이스')) {
    return Icons.local_drink_rounded;
  }
  if (memo.contains('녹차') || memo.contains('티')) {
    return Icons.emoji_food_beverage_rounded;
  }
  if (memo.contains('라테')) return Icons.coffee_rounded;
  if (memo.contains('매장')) return Icons.storefront_rounded;
  return Icons.local_cafe_rounded;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.now});

  final StampRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      leading: CircleAvatar(
        backgroundColor: colors.tertiaryContainer,
        foregroundColor: colors.onTertiaryContainer,
        child: Icon(_drinkIcon(record.memo)),
      ),
      title: Text(record.memo, style: textTheme.titleMedium),
      subtitle: Text(
        AppDateFormat.dateTime(record.stampedAt, now: now),
        style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
      trailing: Text(
        '+${record.count}',
        style: textTheme.titleMedium?.copyWith(color: colors.primary),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          children: [
            Icon(Icons.local_cafe_outlined, size: 40, color: colors.outline),
            const SizedBox(height: AppSpacing.sm),
            Text('아직 적립 내역이 없어요', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '음료를 주문하고 첫 스탬프를 받아 보세요.',
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
