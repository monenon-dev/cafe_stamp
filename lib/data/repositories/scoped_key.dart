/// 계정별 저장 키. [scope]가 비어 있으면 [key] 그대로 쓴다.
String scopedKey(String scope, String key) =>
    scope.isEmpty ? key : '$scope.$key';
