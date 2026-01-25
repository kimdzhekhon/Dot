import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/core/design_system/app_responsive_layout.dart';
import 'package:dot/core/design_system/app_theme.dart';
import 'package:dot/features/scan/presentation/dot_animation.dart';
import 'package:dot/features/scan/presentation/scan_controller.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final text = _textController.text;
    if (text.isNotEmpty) {
      ref.read(scanProvider.notifier).analyzeText(text);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _onReset() {
    ref.read(scanProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final dotState = scanState.dotState;
    final isIdle = dotState == DotState.idle;
    // App Icon Blue
    final primaryBlue = AppTheme.analyzing; 

    return AppResponsiveLayout(
      child: Stack(
        children: [
          // 1. Blue Header Box
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Result Logic (Show score if exists, else show Icon)
                    if (scanState.score != null) ...[
                      Text(
                        '${scanState.score}',
                        style: AppTheme.displayLarge.copyWith(color: Colors.white),
                      ),
                      Text(
                        scanState.message ?? '',
                        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                      ),
                    ] else ...[
                       // Placeholder Icon
                       const Icon(Icons.shield, size: 80, color: Colors.white),
                    ]
                  ],
                ),
              ),
            ),
          ),

          // 2. Input Field (Blue)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: primaryBlue, // User requested Blue Input
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: '의심되는 문자나 URL을 붙여넣으세요...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.paste, color: Colors.white70),
                ),
                onSubmitted: (_) => _onSubmit(),
              ),
            ),
          ),
          
          // Loading Overlay
          if (dotState == DotState.analyzing)
             const Center(child: CircularProgressIndicator(color: AppTheme.analyzing)),
        ],
      ),
    );
  }
}
