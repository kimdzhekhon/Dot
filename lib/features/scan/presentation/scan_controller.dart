import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/features/scan/presentation/dot_animation.dart';

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
  ScanViewModel() : super(ScanState(dotState: DotState.idle));

  Future<void> analyzeText(String text) async {
    // 1. Idle -> Analyzing
    state = state.copyWith(dotState: DotState.analyzing);

    // Mocking Delay (Vibe)
    await Future.delayed(const Duration(seconds: 3));

    // Mocking Result (Random -> Deterministic for now)
    final score = 88; // Hardcoded for Vibe Check
    final isSafe = score < 50;

    state = state.copyWith(
      dotState: isSafe ? DotState.safe : DotState.dangerous,
      score: score,
      message: isSafe ? "This looks Safe." : "This score is ominous.",
    );
  }

  void reset() {
    state = ScanState(dotState: DotState.idle);
  }
}

final scanProvider = StateNotifierProvider<ScanViewModel, ScanState>((ref) {
  return ScanViewModel();
});
