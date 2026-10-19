import 'package:intl/intl.dart';

/// 한국어 날짜 표기.
abstract final class AppDateFormat {
  static final _sameYear = DateFormat('M월 d일 HH:mm');
  static final _otherYear = DateFormat('yyyy년 M월 d일 HH:mm');
  static final _date = DateFormat('yyyy년 M월 d일');

  /// "10월 16일 14:30". 올해가 아니면 연도를 붙인다.
  static String dateTime(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    return (value.year == reference.year ? _sameYear : _otherYear).format(
      value,
    );
  }

  /// "2027년 1월 14일"
  static String date(DateTime value) => _date.format(value);

  /// [target] 날짜까지 남은 일수. 시각은 무시하고 날짜만 비교한다.
  static int daysUntil(DateTime target, {DateTime? now}) {
    final r = now ?? DateTime.now();
    return DateTime.utc(
      target.year,
      target.month,
      target.day,
    ).difference(DateTime.utc(r.year, r.month, r.day)).inDays;
  }

  /// "D-3", 당일이면 "D-DAY"
  static String dDay(DateTime target, {DateTime? now}) {
    final days = daysUntil(target, now: now);
    return days <= 0 ? 'D-DAY' : 'D-$days';
  }
}
