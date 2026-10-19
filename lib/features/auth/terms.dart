/// 회원가입 약관 항목.
enum Terms {
  service(
    '서비스 이용약관',
    required: true,
    body:
        '모아 스탬프는 카페 스탬프 적립과 쿠폰 사용을 돕는 서비스예요.\n\n'
        '적립한 스탬프와 받은 쿠폰은 가입한 계정에 연결되며, 다른 사람에게 넘겨줄 수 없어요.\n\n'
        '부정한 방법으로 적립한 스탬프와 쿠폰은 취소될 수 있어요.',
  ),
  privacy(
    '개인정보 수집·이용',
    required: true,
    body:
        '수집 항목: 이름, 이메일, 스탬프 적립·쿠폰 이용 기록\n\n'
        '이용 목적: 회원 확인, 스탬프 적립과 쿠폰 발급\n\n'
        '보관 기간: 회원 탈퇴 시 바로 삭제\n\n'
        '이 앱은 포트폴리오용 샘플이라 입력한 정보를 서버로 보내지 않고 이 기기에만 저장해요.',
  ),
  marketing(
    '혜택·이벤트 알림 받기',
    required: false,
    body:
        '새 쿠폰과 이벤트 소식을 알려 드려요.\n\n'
        '동의하지 않아도 서비스를 이용할 수 있고, 언제든 다시 바꿀 수 있어요.',
  );

  const Terms(this.title, {required this.required, required this.body});

  final String title;
  final bool required;
  final String body;

  /// "[필수] 서비스 이용약관"
  String get label => '[${required ? '필수' : '선택'}] $title';
}
