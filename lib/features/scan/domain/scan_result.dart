import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_result.freezed.dart';

@freezed
class ScanResult with _$ScanResult {
  const factory ScanResult({
    required int score, // 0 to 100
    required String message,
    required bool isSafe,
    Map<String, dynamic>? details,
  }) = _ScanResult;
}
