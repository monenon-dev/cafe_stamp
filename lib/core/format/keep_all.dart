/// 한국어 단어 중간에서 줄이 바뀌지 않게 한다 (CSS의 `word-break: keep-all`과 같은 효과).
///
/// Flutter는 한글을 글자 단위로 줄바꿈해서 "보여 주세요"가 "보 / 여 주세요"처럼 끊길 수 있다.
/// 띄어쓰기가 없는 글자 사이에 보이지 않는 단어 결합 문자(U+2060)를 넣어 띄어쓰기에서만 줄이 바뀌게 한다.
extension KeepAll on String {
  String get keepAll =>
      replaceAllMapped(RegExp(r'(\S)(?=\S)'), (m) => '${m[1]}⁠');
}
