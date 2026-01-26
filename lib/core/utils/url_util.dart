
class UrlUtil {
  // 인스턴스화 방지
  UrlUtil._();

  /// 텍스트에서 URL만 추출합니다.
  /// 
  /// 예: "안녕하세요 https://google.com 방문해주세요" -> ["https://google.com"]
  static List<String> extractUrls(String text) {
    // URL 매칭을 위한 정규 표현식 개선 (3차)
    // 1. 프로토콜 (http, https 등)로 시작하는 경우: 모든 문자 허용하되 공백 전까지
    // 2. www. 으로 시작하는 경우
    // 3. 프로토콜 없이 도메인만 있는 경우 (google.com 등): 
    //    - TLD가 2자 이상.
    //    - 오탐지 방지: 뒤에 공백, 문장 부호(.,?!), 슬래시(/), 또는 문장 끝($)이 와야 함.
    //    - 이렇게 하면 'EXCLUDED.row_count'의 '_'는 허용되지 않아 매칭 실패함.
    final RegExp urlRegExp = RegExp(
      r'((https?:\/\/[^\s]+)' // http:// 또는 https:// 로 시작 (공백으로 구분)
      r'|(www\.[^\s]+)'       // www. 으로 시작 (공백으로 구분)
      r'|([a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}(?=\s|[\.,?!]|$|\/)))', // 도메인 뒤에 구분자 확인
      caseSensitive: false,
    );

    final Iterable<RegExpMatch> matches = urlRegExp.allMatches(text);

    return matches.map((match) => text.substring(match.start, match.end)).toList();
  }
  
  /// 텍스트에 URL이 포함되어 있는지 확인합니다.
  static bool hasUrl(String text) {
    final urls = extractUrls(text);
    return urls.isNotEmpty;
  }
}
