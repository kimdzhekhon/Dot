import 'package:fpdart/fpdart.dart';
import 'package:dot/core/network/network_exception.dart';
import 'package:dot/features/scan/domain/scan_repository.dart';
import 'package:dot/features/scan/domain/scan_result.dart';
import 'package:dot/features/scan/domain/scan_type.dart';


class ScanTextUseCase {
  final ScanRepository _repository;

  ScanTextUseCase(this._repository);

  Future<Either<NetworkException, ScanResult>> call(String text, ScanType type) {
    return _repository.scanText(text, type);
  }
}

