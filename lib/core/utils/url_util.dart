
class UrlUtil {
  // 인스턴스화 방지
  UrlUtil._();

  /// 텍스트에서 URL만 추출합니다.
  /// 
  /// 예: "안녕하세요 https://google.com 방문해주세요" -> ["https://google.com"]
  static List<String> extractUrls(String text) {
    // URL 매칭을 위한 정규 표현식 개선
    // 1. 프로토콜 (http, https, ftp 등) 또는 www로 시작하는 경우
    // 2. 또는 도메인 패턴 (example.com) - 최소 1개 이상의 점(.)을 포함하고, 
    //    TLD(Top Level Domain)가 2~6자의 알파벳/숫자로 구성된 경우
    final RegExp urlRegExp = RegExp(
      r'((([a-zA-Z0-9]+:\/\/)|(www\.))[a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}' // 프로토콜/www 있는 경우
      r'|([a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z]{2,6}))' // 프로토콜 없는 도메인 (TLD는 최소 2글자 이상, 주로 알파벳)
      r'(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?', // 경로(Path) 및 쿼리 파라미터
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
