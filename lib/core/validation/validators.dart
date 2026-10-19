/// 입력값 검사. 문제가 있으면 화면에 보여 줄 안내 문구를, 없으면 null을 돌려준다.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이름을 입력해 주세요.';
    if (v.length < 2 || v.length > 10) return '이름은 2~10자로 입력해 주세요.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이메일을 입력해 주세요.';
    if (!_email.hasMatch(v)) return '이메일 형식이 맞지 않아요.';
    return null;
  }

  /// 로그인용: 비어 있는지만 본다.
  static String? requiredPassword(String? value) =>
      (value == null || value.isEmpty) ? '비밀번호를 입력해 주세요.' : null;

  /// 가입용: 8자 이상, 영문과 숫자를 모두 포함.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '비밀번호를 입력해 주세요.';
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
