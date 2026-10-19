import 'package:flutter/widgets.dart';

/// 간격 토큰. 화면에서는 숫자 대신 이 값을 사용한다.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// 화면 좌우·상하 기본 여백
  static const page = EdgeInsets.fromLTRB(lg, xs, lg, xxl);
}

/// 모서리 반경 토큰.
abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// 모션 토큰.
abstract final class AppMotion {
  /// 스탬프가 새로 찍힐 때의 확대 애니메이션
  static const stampPop = Duration(milliseconds: 300);
}
