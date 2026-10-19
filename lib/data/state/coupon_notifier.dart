import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coupon.dart';
import '../repositories/repository_providers.dart';

/// 쿠폰함 상태. 최신 발급순으로 정렬된 쿠폰 목록.
class CouponNotifier extends Notifier<List<Coupon>> {
  /// 사용 처리 중인 쿠폰 id. 같은 쿠폰이 두 번 사용 처리되지 않게 막는다.
  final _using = <String>{};

  @override
  List<Coupon> build() => ref.watch(couponRepositoryProvider).loadAll();

  /// 새 쿠폰을 쿠폰함 맨 앞에 추가하고 저장한다.
  Future<void> issue(Coupon coupon) async {
    final next = [coupon, ...state];
    await ref.read(couponRepositoryProvider).saveAll(next);
    state = next;
  }

  /// 쿠폰을 사용 처리한다.
  ///
  /// 사용 가능한 쿠폰이 아니거나 이미 처리 중이면 false를 돌려준다.
  Future<bool> use(String id) async {
    if (_using.contains(id)) return false;
    final now = ref.read(clockProvider)();
    final index = state.indexWhere((c) => c.id == id);
    if (index < 0 || state[index].statusAt(now) != CouponStatus.available) {
      return false;
    }

    _using.add(id);
    try {
      final next = [...state]..[index] = state[index].markUsed(now);
      await ref.read(couponRepositoryProvider).saveAll(next);
      state = next;
      return true;
    } finally {
      _using.remove(id);
    }
  }
}

final couponsProvider = NotifierProvider<CouponNotifier, List<Coupon>>(
  CouponNotifier.new,
);

/// id로 쿠폰 1장 찾기. 없으면 null.
final couponByIdProvider = Provider.family<Coupon?, String>((ref, id) {
  for (final coupon in ref.watch(couponsProvider)) {
    if (coupon.id == id) return coupon;
  }
  return null;
});

/// 상태별 쿠폰 목록.
///
/// - 사용 가능: 만료가 가까운 순
/// - 사용 완료: 최근 사용순
/// - 만료: 최근 만료순
final couponsByStatusProvider = Provider.family<List<Coupon>, CouponStatus>((
  ref,
  status,
) {
  final now = ref.watch(clockProvider)();
  final list = ref
      .watch(couponsProvider)
      .where((c) => c.statusAt(now) == status)
      .toList();
  switch (status) {
    case CouponStatus.available:
      list.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    case CouponStatus.used:
      list.sort((a, b) => b.usedAt!.compareTo(a.usedAt!));
    case CouponStatus.expired:
      list.sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
  }
  return list;
});

/// 지금 사용할 수 있는 쿠폰. 만료가 가까운 순으로 정렬한다.
final availableCouponsProvider = Provider<List<Coupon>>(
  (ref) => ref.watch(couponsByStatusProvider(CouponStatus.available)),
);
