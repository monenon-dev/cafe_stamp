import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/state/coupon_notifier.dart';
import '../../data/state/stamp_notifier.dart';
import '../../widgets/stamp_history_list.dart';
import '../../widgets/titled_page.dart';
import 'widgets/coupon_summary_tile.dart';
import 'widgets/stamp_summary_card.dart';

/// 홈 탭: 인사말, 스탬프 진행 요약, 쿠폰 요약, 최근 적립.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _recentLimit = 3;

  static String _greeting(DateTime now) => switch (now.hour) {
    >= 5 && < 12 => '좋은 아침이에요',
    >= 12 && < 18 => '좋은 오후예요',
    >= 18 && < 22 => '좋은 저녁이에요',
    _ => '늦은 시간에도 반가워요',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(stampProvider).card;
    final available = ref.watch(availableCouponsProvider);
    final now = ref.watch(clockProvider)();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TitledPage(
      title: _greeting(now),
      actions: [
        IconButton(
          tooltip: '멤버십 QR',
          icon: const Icon(Icons.qr_code_2_rounded),
          onPressed: () => context.push(AppRoutes.membership),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            '오늘 마신 한 잔도 잊지 말고 스탬프로 모아 두세요.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StampSummaryCard(
            card: card,
            onStampTap: () => context.go(AppRoutes.stamp),
          ),
          const SizedBox(height: AppSpacing.md),
          CouponSummaryTile(
            available: available,
            now: now,
            onTap: () => context.go(AppRoutes.coupons),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(child: Text('최근 적립', style: textTheme.titleMedium)),
              if (card.history.length > _recentLimit)
                TextButton(
                  onPressed: () => context.go(AppRoutes.stamp),
                  child: const Text('전체 보기'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          StampHistoryList(history: card.history, limit: _recentLimit),
        ],
      ),
    );
  }
}
