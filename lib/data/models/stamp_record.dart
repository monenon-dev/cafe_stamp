/// 스탬프 적립 이력 1건.
class StampRecord {
  const StampRecord({
    required this.id,
    required this.stampedAt,
    required this.count,
    required this.memo,
  });

  final String id;
  final DateTime stampedAt;

  /// 이번에 적립된 스탬프 수 (예: 음료 2잔 주문 시 2)
  final int count;

  /// 적립 사유 (예: "아메리카노 2잔 주문")
  final String memo;

  factory StampRecord.fromJson(Map<String, dynamic> json) => StampRecord(
    id: json['id'] as String,
    stampedAt: DateTime.parse(json['stampedAt'] as String),
    count: json['count'] as int,
    memo: json['memo'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'stampedAt': stampedAt.toIso8601String(),
    'count': count,
    'memo': memo,
  };
}
