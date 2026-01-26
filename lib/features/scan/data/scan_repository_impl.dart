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
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        url = text;
      }

      // 2. Parallel API Calls (Google & VT) & RPC check for URLs
      Map<String, dynamic> googleResult = {};
      Map<String, dynamic> vtResult = {};
      Map<String, dynamic> webListResult = {'found': false};

      if (url != null) {
        if (type == ScanType.address) {
          webListResult = await _dataSource.checkWebList(url);
          
          if (webListResult['found'] == true) {
            final isWhitelisted = webListResult['status'] == 'whitelisted';
            if (isWhitelisted) {
              return Right(ScanResult(
                score: 0,
                isSafe: true,
                message: "${webListResult['site_name']}\n공식 인증된 안전한 사이트입니다.",
                details: webListResult,
              ));
            } else if (webListResult['status'] == 'blacklisted') {
              return Right(ScanResult(
                score: 100,
                isSafe: false,
                message: "블랙리스트에 등록된 위험한 사이트입니다.",
                details: webListResult,
              ));
            }
          }
        }

        // Proceed to other scans if not conclusive from RPC or if it's a message type
        final results = await Future.wait([
          _dataSource.checkGoogleSafeBrowsing(url),
          _dataSource.scanUrlVt(url),
        ]);
        googleResult = results[0];
        vtResult = results[1];
      }

      // 3. RPC Call for scoring (mainly for messages or unknown URLs)
      final score = await _dataSource.calculateDotScore(
        message: text,
        googleResult: googleResult,
        vtResult: vtResult,
        url: url,
      );

      // 4. Map to Entity
      final isSafe = score < 50;
      final message = isSafe 
          ? (type == ScanType.address ? "데이터베이스에 없으나 안전해보입니다." : "안전해보입니다.") 
          : "위협이 감지되었습니다 ($score점).";

      return Right(ScanResult(
        score: score,
        message: message,
        isSafe: isSafe,
        details: {'google': googleResult, 'vt': vtResult, 'webList': webListResult},
      ));
    } on NetworkException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkException(message: e.toString()));
    }
  }
}

