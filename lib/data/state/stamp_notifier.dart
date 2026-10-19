import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coupon.dart';
import '../models/stamp_card.dart';
import '../models/stamp_record.dart';
import '../repositories/repository_providers.dart';
import 'coupon_notifier.dart';

/// 스탬프 화면 상태.
class StampState {
  const StampState({required this.card, this.isSaving = false});

  final StampCard card;

  /// 적립 처리 중 여부. true인 동안에는 추가 적립 요청을 무시한다.
  final bool isSaving;

  StampState copyWith({StampCard? card, bool? isSaving}) =>
      StampState(card: card ?? this.card, isSaving: isSaving ?? this.isSaving);
}

/// 적립 결과.
sealed class StampResult {
  const StampResult();
}

/// 스탬프가 1개 적립됨.
class Stamped extends StampResult {
  const Stamped(this.card);

  final StampCard card;
}

/// 목표 개수를 채워 쿠폰이 발급되고 카드가 0개로 리셋됨.
class CouponIssued extends StampResult {
  const CouponIssued(this.coupon);

  final Coupon coupon;
}

class StampNotifier extends Notifier<StampState> {
  static const defaultMemo = '매장 방문 적립';
  static const rewardTitle = '무료 음료 쿠폰';
  static const rewardDescription = '스탬프 10개를 모아 받은 쿠폰이에요. 원하는 음료 1잔을 무료로 드려요.';
  static const rewardValidity = Duration(days: 90);

  @override
  StampState build() =>
      StampState(card: ref.watch(stampRepositoryProvider).load());

  /// 스탬프를 1개 적립한다.
  ///
  /// 목표 개수에 도달하면 [CouponIssued]를 돌려주고 카드 개수를 0으로 되돌린다
  /// (초과분은 이월하지 않으며, 적립 이력은 누적해서 보관한다).
  /// 이전 요청을 처리하는 중이면 아무것도 하지 않고 null을 돌려준다.
  Future<StampResult?> stamp({String memo = defaultMemo}) async {
    if (state.isSaving) return null;
    state = state.copyWith(isSaving: true);

    try {
      final now = ref.read(clockProvider)();
      final card = state.card;
      final record = StampRecord(
        id: 'stamp-${now.microsecondsSinceEpoch}',
        stampedAt: now,
        count: 1,
        memo: memo,
      );
      final history = [record, ...card.history];
      final filled = card.count + 1;

      if (filled >= card.goal) {
        final coupon = Coupon(
          id: 'coupon-reward-${now.microsecondsSinceEpoch}',
          title: rewardTitle,
          description: rewardDescription,
          issuedAt: now,
          expiresAt: now.add(rewardValidity),
        );
        final reset = card.copyWith(count: 0, history: history);
        await ref.read(couponsProvider.notifier).issue(coupon);
        await ref.read(stampRepositoryProvider).save(reset);
        state = StampState(card: reset);
        return CouponIssued(coupon);
      }

      final next = card.copyWith(count: filled, history: history);
      await ref.read(stampRepositoryProvider).save(next);
      state = StampState(card: next);
      return Stamped(next);
    } catch (_) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

final stampProvider = NotifierProvider<StampNotifier, StampState>(
  StampNotifier.new,
);
