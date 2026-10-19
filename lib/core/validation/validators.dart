import '../format/keep_all.dart';

/// 입력값 검사. 문제가 있으면 화면에 보여 줄 안내 문구를, 없으면 null을 돌려준다.
abstract final class Validators {
  /// 영문 이메일만 허용한다.
  static final _email = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$',
  );

  /// 한글 자모·완성형 글자.
  ///
  /// 한국어 키보드는 이메일 칸에서도 한국어 자판을 그대로 보여 줘서
  /// "moa"를 치려다 "ㅡㅐㅁ"가 들어가는 일이 흔하다. 이때는 형식 오류 대신
  /// 키보드를 바꾸라고 알려 준다.
  static final _hangul = RegExp('[ㄱ-ㆎ가-힣]');

  static final hangulInEmail =
      '이메일은 영문으로 입력해 주세요. 키보드에서 한/영을 바꿀 수 있어요.'.keepAll;
  static final hangulInPassword =
      '비밀번호는 영문과 숫자로 입력해 주세요. 키보드에서 한/영을 바꿀 수 있어요.'.keepAll;

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이름을 입력해 주세요.';
    if (v.length < 2 || v.length > 10) return '이름은 2~10자로 입력해 주세요.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이메일을 입력해 주세요.';
    if (_hangul.hasMatch(v)) return hangulInEmail;
    if (!_email.hasMatch(v)) return '이메일 형식이 맞지 않아요.';
    return null;
  }

  /// 로그인용: 비어 있는지와 한글이 섞였는지만 본다.
  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해 주세요.';
    if (_hangul.hasMatch(value)) return hangulInPassword;
    return null;
  }

  /// 가입용: 8자 이상, 영문과 숫자를 모두 포함.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '비밀번호를 입력해 주세요.';
    if (_hangul.hasMatch(v)) return hangulInPassword;
    if (v.length < 8) return '비밀번호는 8자 이상이어야 해요.';
    if (!RegExp('[A-Za-z]').hasMatch(v) || !RegExp('[0-9]').hasMatch(v)) {
      return '영문과 숫자를 함께 넣어 주세요.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return '비밀번호를 한 번 더 입력해 주세요.';
    if (value != password) return '비밀번호가 서로 달라요.';
    return null;
  }
}
