import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coupon.dart';
import '../repositories/repository_providers.dart';
import 'coupon_notifier.dart';
import 'stamp_notifier.dart';

/// 누적 스탬프 수에 따른 회원 등급.
enum MemberTier {
  sprout('새싹 회원', 0),
  regular('단골 회원', 10),
  devoted('열혈 단골', 30);

  const MemberTier(this.label, this.minStamps);

  final String label;
  final int minStamps;

  static MemberTier of(int totalStamps) =>
      values.lastWhere((t) => totalStamps >= t.minStamps);

  /// 다음 등급. 최고 등급이면 null.
  MemberTier? get next => index + 1 < values.length ? values[index + 1] : null;
}

/// 내 정보 화면 통계.
class ProfileStats {
  const ProfileStats({
    required this.totalStamps,
    required this.receivedCoupons,
    required this.usedCoupons,
    required this.firstActivityAt,
  });

  /// 지금까지 적립한 스탬프 수 (카드 리셋과 관계없이 누적)
  final int totalStamps;
  final int receivedCoupons;
  final int usedCoupons;

  /// 가장 오래된 적립·쿠폰 발급 시각. 기록이 없으면 null
  final DateTime? firstActivityAt;

  MemberTier get tier => MemberTier.of(totalStamps);

  /// 다음 등급까지 남은 스탬프 수. 최고 등급이면 0
  int get stampsToNextTier {
    final next = tier.next;
    return next == null ? 0 : next.minStamps - totalStamps;
  }

  /// 현재 등급 구간에서의 진행률 (0~1). 최고 등급이면 1
  double get tierProgress {
    final next = tier.next;
    if (next == null) return 1;
    return (totalStamps - tier.minStamps) / (next.minStamps - tier.minStamps);
  }
}

final profileStatsProvider = Provider<ProfileStats>((ref) {
  final history = ref.watch(stampProvider).card.history;
  final coupons = ref.watch(couponsProvider);
  final now = ref.watch(clockProvider)();

  final dates = [
    for (final r in history) r.stampedAt,
    for (final c in coupons) c.issuedAt,
  ];

  return ProfileStats(
    totalStamps: history.fold(0, (sum, r) => sum + r.count),
    receivedCoupons: coupons.length,
    usedCoupons: coupons
        .where((c) => c.statusAt(now) == CouponStatus.used)
        .length,
    firstActivityAt: dates.isEmpty
        ? null
        : dates.reduce((a, b) => a.isBefore(b) ? a : b),
  );
});

/// 데이터 관리 동작. 저장소를 바꾼 뒤 상태를 다시 불러온다.
class AppDataController {
  AppDataController(this._ref);

  final Ref _ref;

  Future<void> restoreSample() async {
    await restoreMockData(
      _ref.read(sharedPreferencesProvider),
      scope: _ref.read(dataScopeProvider),
      now: _ref.read(clockProvider)(),
    );
    _reload();
  }

  Future<void> clearAll() async {
    await clearAllData(
      _ref.read(sharedPreferencesProvider),
      scope: _ref.read(dataScopeProvider),
    );
    _reload();
  }

  void _reload() {
    _ref.invalidate(stampProvider);
    _ref.invalidate(couponsProvider);
  }
}

final appDataControllerProvider = Provider<AppDataController>(
  AppDataController.new,
);
