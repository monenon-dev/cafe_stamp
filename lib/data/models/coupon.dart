enum CouponStatus { available, used, expired }

/// 쿠폰함에 보관되는 쿠폰.
class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.issuedAt,
    required this.expiresAt,
    this.usedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime issuedAt;
  final DateTime expiresAt;

  /// 사용한 시각. 사용 전이면 null
  final DateTime? usedAt;

  /// [now] 기준 쿠폰 상태. 사용 여부가 만료보다 우선한다.
  CouponStatus statusAt(DateTime now) {
    if (usedAt != null) return CouponStatus.used;
    if (now.isAfter(expiresAt)) return CouponStatus.expired;
    return CouponStatus.available;
  }

  /// 매장에서 확인하는 쿠폰 번호 (예: "MOA 4821 0937").
  ///
  /// 샘플 앱이라 서버 발급 대신 id에서 결정적으로 만들어 낸다.
  String get displayCode {
    // FNV-1a 32bit: 실행 환경과 관계없이 항상 같은 값을 낸다.
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    final digits = (hash % 100000000).toString().padLeft(8, '0');
    return 'MOA ${digits.substring(0, 4)} ${digits.substring(4)}';
  }

  Coupon markUsed(DateTime at) => Coupon(
    id: id,
    title: title,
    description: description,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
    usedAt: at,
  );

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    issuedAt: DateTime.parse(json['issuedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    usedAt: json['usedAt'] == null
        ? null
        : DateTime.parse(json['usedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'usedAt': usedAt?.toIso8601String(),
  };
}
