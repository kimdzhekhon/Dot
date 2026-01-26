import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/features/scan/presentation/dot_animation.dart';
import 'package:dot/features/scan/domain/scan_text_usecase.dart';
import 'package:dot/features/scan/presentation/scan_providers.dart';
import 'package:dot/features/scan/domain/scan_type.dart';


// Simple state holder for now. Will eventually include Entity/Model.

class ScanState {
  final DotState dotState;
  final String? message;
  final int? score;
  final ScanType? scanType;
  final Map<String, dynamic>? details;

  ScanState({
    required this.dotState,
    this.message,
    this.score,
    this.scanType,
    this.details,
  });

  ScanState copyWith({
    DotState? dotState,
    String? message,
    int? score,
    ScanType? scanType,
    Map<String, dynamic>? details,
    bool clearScanType = false,
  }) {
    return ScanState(
      dotState: dotState ?? this.dotState,
      message: message ?? this.message,
      score: score ?? this.score,
      scanType: clearScanType ? null : (scanType ?? this.scanType),
      details: details ?? this.details,
    );
  }
}


class ScanViewModel extends StateNotifier<ScanState> {
  final ScanTextUseCase _scanTextUseCase;

  ScanViewModel(this._scanTextUseCase) : super(ScanState(dotState: DotState.idle));

  void changeScanType(ScanType? type) {
    state = state.copyWith(
      scanType: type,
      clearScanType: type == null,
      details: null,
    );
    if (type == null) {
      reset();
    }
  }

  Future<void> analyzeText(String text) async {
    state = state.copyWith(dotState: DotState.analyzing);

    final result = await _scanTextUseCase(text, state.scanType!);


    result.fold(
      (failure) {
        state = state.copyWith(
          dotState: DotState.warning, 
          message: failure.message,
          score: -1,
        );
      },
      (success) {
        DotState dotState;
        if (success.score >= 80) {
          dotState = DotState.dangerous;
        } else if (success.score >= 40) {
          dotState = DotState.warning;
        } else {
          dotState = DotState.safe;
        }

        state = state.copyWith(
          dotState: dotState,
          score: success.score,
          message: success.message,
          details: success.details,
        );
      },

    );
  }

  void reset() {
    state = state.copyWith(dotState: DotState.idle, score: null, message: null, details: null);
  }
}

final scanProvider = StateNotifierProvider<ScanViewModel, ScanState>((ref) {
  return ScanViewModel(ref.read(scanTextUseCaseProvider));
});
