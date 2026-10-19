import 'package:flutter_test/flutter_test.dart';
import 'package:moa_stamp/core/format/app_date_format.dart';

void main() {
  test('적립 이력 날짜를 한국어 형식으로 표기한다', () {
    final now = DateTime(2026, 10, 20);
    expect(
      AppDateFormat.dateTime(DateTime(2026, 10, 16, 14, 30), now: now),
      '10월 16일 14:30',
    );
    expect(
      AppDateFormat.dateTime(DateTime(2026, 3, 5, 9, 5), now: now),
      '3월 5일 09:05',
    );
    expect(
      AppDateFormat.dateTime(DateTime(2025, 12, 31, 23, 0), now: now),
      '2025년 12월 31일 23:00',
    );
  });
}
