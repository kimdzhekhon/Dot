import 'package:fpdart/fpdart.dart';
import 'package:dot/core/network/network_exception.dart';
import 'package:dot/features/scan/domain/scan_result.dart';
import 'package:dot/features/scan/domain/scan_type.dart';


abstract class ScanRepository {
  /// Analyzes the given text (URL or Message) and returns a Score.
  Future<Either<NetworkException, ScanResult>> scanText(String text, ScanType type);
}

