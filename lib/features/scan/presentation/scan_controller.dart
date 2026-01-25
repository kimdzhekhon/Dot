import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/features/scan/presentation/dot_animation.dart';
import 'package:dot/features/scan/domain/scan_text_usecase.dart';
import 'package:dot/features/scan/presentation/scan_providers.dart';

// Simple state holder for now. Will eventually include Entity/Model.
class ScanState {
  final DotState dotState;
  final String? message;
  final int? score;

  ScanState({
    required this.dotState,
    this.message,
    this.score,
  });

  ScanState copyWith({DotState? dotState, String? message, int? score}) {
    return ScanState(
      dotState: dotState ?? this.dotState,
      message: message ?? this.message,
      score: score ?? this.score,
    );
  }
}


class ScanViewModel extends StateNotifier<ScanState> {
  final ScanTextUseCase _scanTextUseCase;

  ScanViewModel(this._scanTextUseCase) : super(ScanState(dotState: DotState.idle));

  Future<void> analyzeText(String text) async {
    // 1. Idle -> Analyzing
    state = state.copyWith(dotState: DotState.analyzing);

    // 2. UseCase Call
    final result = await _scanTextUseCase(text);

    result.fold(
      (failure) {
        state = state.copyWith(
          dotState: DotState.warning, 
          message: failure.message,
          score: -1, // Error indicator
        );
      },
      (success) {
        state = state.copyWith(
          dotState: success.isSafe ? DotState.safe : DotState.dangerous,
          score: success.score,
          message: success.message,
        );
      },
    );
  }

  void reset() {
    state = ScanState(dotState: DotState.idle, score: null, message: null);
  }
}

final scanProvider = StateNotifierProvider<ScanViewModel, ScanState>((ref) {
  return ScanViewModel(ref.read(scanTextUseCaseProvider));
});
