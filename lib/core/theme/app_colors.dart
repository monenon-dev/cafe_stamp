import 'package:flutter/material.dart';

/// 모아 스탬프 브랜드 색상.
abstract final class AppColors {
  // 다크 로스트 팔레트: 모든 색은 커피 계열(에스프레소·모카·캐러멜·라테) 안에서만 쓴다.
  // 면적 비율은 밝은 배경·라테 60%, 에스프레소 30%, 캐러멜 포인트 10%.

  /// 주색 – 모카. 버튼·도장·선택 표시. 흰 글자 대비 5.8:1.
  static const primary = Color(0xFF8A5A3B);

  /// 진한 면 – 에스프레소. 홈 요약 카드, 할인 쿠폰, 등급 배지.
  static const accent = Color(0xFF3B2A21);

  /// 라테 – 연한 배지·아이콘 배경, 에스프레소 위의 버튼.
  static const accentContainer = Color(0xFFEFE3D3);

  /// 라테 위의 글자·아이콘 (대비 11:1)
  static const onAccentContainer = Color(0xFF3B2A21);

  /// 캐러멜 – 포인트 전용. 에스프레소 같은 어두운 면 위의 진행 막대·숫자·아이콘에만 쓴다.
  /// 밝은 배경 위에서는 대비가 낮아 글자색으로 쓰지 않는다.
  static const caramel = Color(0xFFC8925E);

  /// 화면 배경 – 주색과 같은 색상각대의 따뜻한 아이보리
  static const background = Color(0xFFF7F1E8);

  /// 카드·시트 등 한 단계 밝은 표면
  static const surface = Color(0xFFFFFCF7);

  /// 구분선·비활성 테두리
  static const outline = Color(0xFFE5D9CA);

  /// 사용 완료·만료처럼 비활성 상태의 면 – 채도를 뺀 라테 회색
  static const inactive = Color(0xFFE8E1D7);

  /// 카드 그림자 – 에스프레소 (투명도를 낮춰서 사용)
  static const shadow = Color(0xFF3B2A21);

  /// 본문 텍스트
  static const textPrimary = Color(0xFF1F1B16);

  /// 보조 텍스트
  static const textSecondary = Color(0xFF6B6459);
}
