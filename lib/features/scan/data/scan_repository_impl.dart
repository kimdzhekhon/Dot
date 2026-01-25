import 'package:fpdart/fpdart.dart';
import 'package:dot/core/network/network_exception.dart';
import 'package:dot/features/scan/data/scan_remote_datasource.dart';
import 'package:dot/features/scan/domain/scan_repository.dart';
import 'package:dot/features/scan/domain/scan_result.dart';

class ScanRepositoryImpl implements ScanRepository {
  final ScanRemoteDataSource _dataSource;

  ScanRepositoryImpl(this._dataSource);

  @override
  Future<Either<NetworkException, ScanResult>> scanText(String text) async {
    try {
      // 1. Identify URL
      String? url;
      final uri = Uri.tryParse(text);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        url = text;
      }

      // 2. Parallel API Calls (Google & VT)
      // Google Safe Browsing only works on URLs
      final googleResult = url != null 
          ? await _dataSource.checkGoogleSafeBrowsing(url) 
          : <String, dynamic>{};
      
      final vtResult = url != null 
          ? await _dataSource.scanUrlVt(url) 
          : <String, dynamic>{};

      // 3. RPC Call
      final score = await _dataSource.calculateDotScore(
        message: text,
        googleResult: googleResult,
        vtResult: vtResult,
        url: url,
      );

      // 4. Map to Entity
      final isSafe = score < 50;
      final message = isSafe 
          ? "안전해보입니다." 
          : "위협이 감지되었습니다 ($score점).";

      return Right(ScanResult(
        score: score,
        message: message,
        isSafe: isSafe,
        details: {'google': googleResult, 'vt': vtResult},
      ));
    } on NetworkException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkException(message: e.toString()));
    }
  }
}
