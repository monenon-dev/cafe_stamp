import 'stamp_record.dart';

/// 스탬프 카드. 목표 개수를 채우면 무료 음료 쿠폰으로 교환된다.
class StampCard {
  const StampCard({
    required this.count,
    this.goal = defaultGoal,
    this.history = const [],
  });

  static const defaultGoal = 10;

  /// 현재 카드에 모인 스탬프 수
  final int count;

  /// 쿠폰 교환까지 필요한 스탬프 수
  final int goal;

  /// 적립 이력 (최신순)
  final List<StampRecord> history;

  int get remaining => (goal - count).clamp(0, goal);
  bool get isComplete => count >= goal;
  double get progress => goal == 0 ? 0 : (count / goal).clamp(0.0, 1.0);

  StampCard copyWith({int? count, int? goal, List<StampRecord>? history}) =>
      StampCard(
        count: count ?? this.count,
        goal: goal ?? this.goal,
        history: history ?? this.history,
      );

  factory StampCard.fromJson(Map<String, dynamic> json) => StampCard(
    count: json['count'] as int,
    goal: json['goal'] as int? ?? defaultGoal,
    history: (json['history'] as List<dynamic>? ?? [])
        .map((e) => StampRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'count': count,
    'goal': goal,
    'history': history.map((e) => e.toJson()).toList(),
  };
}
