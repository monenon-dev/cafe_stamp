import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/state/stamp_notifier.dart';
import '../../widgets/stamp_history_list.dart';
import '../../widgets/titled_page.dart';
import 'widgets/coupon_issued_dialog.dart';
import 'widgets/stamp_card_view.dart';

/// 적립 탭: 스탬프 카드, 적립 버튼, 적립 이력.
class StampScreen extends ConsumerStatefulWidget {
  const StampScreen({super.key});

  @override
  ConsumerState<StampScreen> createState() => _StampScreenState();
}

class _StampScreenState extends ConsumerState<StampScreen> {
  /// 쿠폰 발급 안내가 떠 있는 동안 카드를 가득 찬 상태로 보여 준다.
  /// (상태는 이미 0개로 리셋됐지만, 10번째 칸이 찍히는 모습을 보여 주기 위함)
  bool _showCompletedCard = false;

  /// 멤버십 QR을 보여 주고, 직원 스캔(데모)이 끝나면 적립한다.
  Future<void> _openMembership() async {
    final scanned = await context.push<bool>(
      AppRoutes.membershipWith(demoScan: true),
    );
    if (scanned == true && mounted) await _onStampPressed();
  }

  Future<void> _onStampPressed() async {
    final result = await ref.read(stampProvider.notifier).stamp();
    if (!mounted || result == null) return;

    switch (result) {
      case Stamped(:final card):
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('스탬프가 적립됐어요. 무료 음료까지 ${card.remaining}개 남았어요.'),
            ),
          );
      case CouponIssued(:final coupon):
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() => _showCompletedCard = true);
        final openCoupons = await CouponIssuedDialog.show(context, coupon);
        if (!mounted) return;
        setState(() => _showCompletedCard = false);
        if (openCoupons) context.go(AppRoutes.coupons);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stampProvider);
    final card = state.card;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return TitledPage(
      title: '적립',
      body: ListView(
        padding: AppSpacing.page,
        children: [
          StampCardView(
            count: _showCompletedCard ? card.goal : card.count,
            goal: card.goal,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: state.isSaving ? null : _openMembership,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: Text(state.isSaving ? '적립하는 중이에요' : 'QR 보여 주고 적립하기'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('적립 이력', style: textTheme.titleMedium),
              const SizedBox(width: AppSpacing.xs),
              if (card.history.isNotEmpty)
                Text(
                  '총 ${card.history.length}건',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StampHistoryList(history: card.history),
        ],
      ),
    );
  }
}
