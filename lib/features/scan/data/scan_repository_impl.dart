import 'package:fpdart/fpdart.dart';
import 'package:dot/core/network/network_exception.dart';
import 'package:dot/features/scan/data/scan_remote_datasource.dart';
import 'package:dot/features/scan/domain/scan_repository.dart';
import 'package:dot/features/scan/domain/scan_result.dart';
import 'package:dot/features/scan/domain/scan_type.dart';


class ScanRepositoryImpl implements ScanRepository {
  final ScanRemoteDataSource _dataSource;

  ScanRepositoryImpl(this._dataSource);

  @override
  Future<Either<NetworkException, ScanResult>> scanText(String text, ScanType type) async {
    try {
      if (type == ScanType.phoneNumber) {
        // Phone Search Flow
        final cleanResult = await _dataSource.searchCleanPhone(text);
        if (cleanResult['found'] == true) {
          final orgName = cleanResult['org_name'] as String;
          final deptName = cleanResult['dept_name'] as String?;
          final deptLabel = (deptName != null && deptName.isNotEmpty) ? " ($deptName)" : "";
          final phone = cleanResult['phone_number'];
          final fax = cleanResult['fax_number'] ?? '-';
          final address = cleanResult['address'] ?? '-';

          return Right(ScanResult(
            score: 0,
            isSafe: true,
            message: "$orgName$deptLabel\n전화: $phone\n팩스: $fax\n주소: $address",
            details: cleanResult,
          ));


        } else {
          return Right(const ScanResult(
            score: 50, // Threshold for warning
            isSafe: false, 
            message: "공공기관 정보공개 데이터에 없습니다",
          ));
        }

      }

      // General Analysis Flow (Messages, URLs)
      // 1. Identify URL
      String? url;
      final uri = Uri.tryParse(text);
      if (uri != null) {
        final scheme = uri.scheme.toLowerCase();
        if (scheme == 'http' || scheme == 'https' || scheme == 'hxxp' || scheme == 'hxxps') {
          url = text;
        }
      }
      
      // If still null but it's an address scan, assume the whole text is the target
      if (url == null && type == ScanType.address) {
        url = text;
      }

      // 2. Parallel API Calls (Google & VT) & RPC check for URLs
      Map<String, dynamic> googleResult = {};

      Map<String, dynamic> whoisResult = {};
      Map<String, dynamic> webListResult = {'found': false};

      if (url != null) {
        if (type == ScanType.address) {
          // 1. Check strict URL first (e.g. specific path in blacklist)
          // Strip existing scheme for cleaner check if needed, but SQL handles prefixes now.
          // We'll pass the text mostly as is, just ensuring no whitespace.
          String cleanUrl = url.trim();
          
          // Remove scheme for consistency in checking (since SQL adds them back)
          // But if user typed hxxp://..., we should check that too.
          // Let's rely on the SQL 'IN' clause which adds prefixes to the input.
          // So if we pass 'click.gl/qVdqG6', SQL checks 'hxxp://click.gl/qVdqG6'.
          // If we pass 'hxxp://click.gl/qVdqG6', SQL checks 'hxxp://hxxp://...' (Bad).
          
          // Normalize: Remove Schemes from input before sending to DB check
          String normalizedInput = cleanUrl
              .replaceAll(RegExp(r'^(http|https|hxxp|hxxps)://', caseSensitive: false), '');
              
          webListResult = await _dataSource.checkWebList(normalizedInput);
          
          // 2. If not found, check the HOST (e.g. domain block)
          // Case: User entered 'site.com/bad' but only 'site.com' is in blacklist.
          if (webListResult['found'] != true) {
             try {
                final uri = Uri.parse(cleanUrl.startsWith('http') ? cleanUrl : 'https://$cleanUrl');
                if (uri.host.isNotEmpty && uri.host != normalizedInput) {
                   // Avoid checking same string twice
                   final hostResult = await _dataSource.checkWebList(uri.host);
                   if (hostResult['found'] == true) {
                      webListResult = hostResult;
                   }
                }
             } catch (_) {}
          }

          if (webListResult['found'] == true) {
            final isWhitelisted = webListResult['status'] == 'whitelisted';
            if (isWhitelisted) {
              return Right(ScanResult(
                score: 0,
                isSafe: true,
                message: "${webListResult['site_name']}\n공식 인증된 안전한 사이트입니다.",
                details: {'webList': webListResult},
              ));
            } else if (webListResult['status'] == 'blacklisted') {
              return Right(ScanResult(
                score: 100,
                isSafe: false,
                message: "블랙리스트에 등록된 위험한 사이트입니다.",
                details: {'webList': webListResult},
              ));
            }
          }
        }

        // Proceed to other scans if not conclusive from RPC or if it's a message type
        final results = await Future.wait<Map<String, dynamic>>([
          _dataSource.checkGoogleSafeBrowsing(url),
          _dataSource.checkWhois(url),
        ]);
        googleResult = results[0];
        whoisResult = results[1];
      }

      // 3. RPC Call for scoring (mainly for messages or unknown URLs)
      final score = await _dataSource.calculateDotScore(
        message: text,
        googleResult: googleResult,
        url: url,
      );

      // 4. Map to Entity
      // 5. Post-Score Analysis for New Domains (Client-side logic as requested)
      // Check if domain is created within 48 hours
      bool isNewDomain = false;
      if (whoisResult.isNotEmpty && whoisResult.containsKey('regDate')) { // KISA key might differ, need to handle parsing robustly
         // Assuming KISA returns 'regDate' or similar in the raw map we returned
         // Actually KISA structure is complex. Let's assume we look for a standard date string if available
         // For now, I will add a parser in the repo or rely on what DataSource returns.
         // DataSource returns `response.data['whois']`.
         // Let's try to parse 'regDate' from it.
         final regDateStr = whoisResult['regDate'] as String?;
         if (regDateStr != null) {
            try {
              // Parse date (Format varies, e.g., YYYY.MM.DD or YYYY-MM-DD)
              final cleanDate = regDateStr.replaceAll('.', '-');
              final regDate = DateTime.parse(cleanDate);
              final diff = DateTime.now().difference(regDate);
              if (diff.inHours.abs() <= 48) {
                 isNewDomain = true;
              }
            } catch (_) {}
         }
      }

      final isSafe = score < 50 && !isNewDomain; // Force unsafe if new domain
      
      String displayMessage = "";
      if (isNewDomain) {
         displayMessage = "생성된 지 얼마 안 된 의심스러운 주소입니다.";
      } else if (isSafe) {
         displayMessage = (type == ScanType.address ? "데이터베이스에 없으나 안전해보입니다." : "안전해보입니다.");
      } else {
         if (type == ScanType.address) {
            displayMessage = "위협이 감지되었습니다";
         } else {
            displayMessage = "위협이 감지되었습니다 ($score점).";
         }
      }

      return Right(ScanResult(
        score: isNewDomain ? (score < 50 ? 50 : score) : score, // Boost score to at least 50 (Warning)
        message: displayMessage,
        isSafe: isSafe,
        details: {
           'google': googleResult, 
           'webList': webListResult,
           'whois': whoisResult,
           'isNewDomain': isNewDomain
        },
      ));
    } on NetworkException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkException(message: e.toString()));
    }
  }
}

