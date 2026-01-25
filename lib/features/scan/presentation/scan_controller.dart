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

  ScanState({
    required this.dotState,
    this.message,
    this.score,
    this.scanType, // Default null = Menu Mode
  });

  ScanState copyWith({
    DotState? dotState,
    String? message,
    int? score,
    ScanType? scanType,
    bool clearScanType = false, // Helper to explicitly set null
  }) {
    return ScanState(
      dotState: dotState ?? this.dotState,
      message: message ?? this.message,
      score: score ?? this.score,
      scanType: clearScanType ? null : (scanType ?? this.scanType),
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
    );
    if (type == null) {
      // Reset state when going back to menu
      reset();
    }
  }

  Future<void> analyzeText(String text) async {
    // 1. Idle -> Analyzing
    state = state.copyWith(dotState: DotState.analyzing);

    // 2. UseCase Call
    final result = await _scanTextUseCase(text, state.scanType!);


    result.fold(
      (failure) {
        state = state.copyWith(
          dotState: DotState.warning, 
          message: failure.message,
          score: -1, // Error indicator
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
        );
      },

    );
  }

  void reset() {
    state = state.copyWith(dotState: DotState.idle, score: null, message: null);
  }
}

final scanProvider = StateNotifierProvider<ScanViewModel, ScanState>((ref) {
  return ScanViewModel(ref.read(scanTextUseCaseProvider));
});
