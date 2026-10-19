/// 회원 계정.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.email,
    required this.memberId,
    required this.createdAt,
    this.marketingAgreed = false,
  });

  final String id;

  /// 화면에 보이는 이름 (닉네임)
  final String name;
  final String email;

  /// 멤버십 QR에 들어가는 8자리 회원 번호
  final String memberId;
  final DateTime createdAt;

  /// 선택 약관(혜택·이벤트 알림) 동의 여부
  final bool marketingAgreed;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    memberId: json['memberId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    marketingAgreed: json['marketingAgreed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'memberId': memberId,
    'createdAt': createdAt.toIso8601String(),
    'marketingAgreed': marketingAgreed,
  };
}
