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

      // 2. Parallel API Calls (Google & VT) - Skipped if URL is null, or adapted
      // For Vibe Coding, we just fire them.
      // In prod, await Future.wait([...])
      final googleResult = await _dataSource.searchGoogle(text);
      final vtResult = url != null ? await _dataSource.scanUrlVt(url) : <String, dynamic>{};

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
          ? "Dot remains calm. It's safe." 
          : "Dot pulses violently. Threat detected ($score%).";

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
