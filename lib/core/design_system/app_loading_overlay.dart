import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 전역 로딩 오버레이 컴포넌트
/// [isLoading]이 true일 때 화면 전체를 반투명한 회색으로 덮고 Lottie 애니메이션을 보여줍니다.
/// 터치 및 조작이 불가능하도록 차단합니다.
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // 터치 이벤트 흡수
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4), // 반투명 회색 배경
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animation/Loading Files.json',
                        width: 200,
                        height: 200,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
