import '../models/coupon.dart';
import '../models/stamp_card.dart';
import '../models/stamp_record.dart';

/// 첫 실행 시 저장소에 넣는 샘플 데이터.
///
/// 날짜는 실행 시점을 기준으로 계산해 언제 열어도 최근 기록처럼 보이게 한다.
abstract final class MockData {
  static StampCard stampCard(DateTime now) {
    final history = [
      StampRecord(
        id: 'stamp-007',
        stampedAt: now.subtract(const Duration(days: 1, hours: 2)),
        count: 1,
        memo: '카페라테 1잔 주문',
      ),
      StampRecord(
        id: 'stamp-006',
        stampedAt: now.subtract(const Duration(days: 3, hours: 5)),
        count: 2,
        memo: '아메리카노 2잔 주문',
      ),
      StampRecord(
        id: 'stamp-005',
        stampedAt: now.subtract(const Duration(days: 6, hours: 1)),
        count: 1,
        memo: '바닐라 라테 1잔 주문',
      ),
      StampRecord(
        id: 'stamp-004',
        stampedAt: now.subtract(const Duration(days: 9, hours: 4)),
        count: 1,
        memo: '콜드브루 1잔 주문',
      ),
      StampRecord(
        id: 'stamp-003',
        stampedAt: now.subtract(const Duration(days: 13, hours: 3)),
        count: 2,
        memo: '아메리카노 1잔, 녹차 라테 1잔 주문',
      ),
    ];
    return StampCard(
      count: history.fold(0, (sum, r) => sum + r.count),
      history: history,
    );
  }

  static List<Coupon> coupons(DateTime now) => [
    Coupon(
      id: 'coupon-free-drink-02',
      title: '아메리카노 1잔 무료',
      description: '스탬프 10개를 모아 받은 쿠폰이에요. 매장에서 직원에게 보여 주세요.',
      issuedAt: now.subtract(const Duration(days: 15)),
      expiresAt: now.add(const Duration(days: 75)),
    ),
    Coupon(
      id: 'coupon-cake-3000',
      title: '조각 케이크 3,000원 할인',
      description: '음료와 함께 조각 케이크를 주문하면 3,000원을 할인해 드려요.',
      issuedAt: now.subtract(const Duration(days: 4)),
      expiresAt: now.add(const Duration(days: 10)),
    ),
    Coupon(
      id: 'coupon-size-up',
      title: '음료 사이즈 업',
      description: '모든 음료를 한 단계 큰 사이즈로 바꿔 드려요.',
      issuedAt: now.subtract(const Duration(days: 40)),
      expiresAt: now.subtract(const Duration(days: 10)),
    ),
    Coupon(
      id: 'coupon-free-drink-01',
      title: '아메리카노 1잔 무료',
      description: '스탬프 10개를 모아 받은 쿠폰이에요. 매장에서 직원에게 보여 주세요.',
      issuedAt: now.subtract(const Duration(days: 60)),
      expiresAt: now.add(const Duration(days: 30)),
      usedAt: now.subtract(const Duration(days: 52)),
    ),
  ];
}
