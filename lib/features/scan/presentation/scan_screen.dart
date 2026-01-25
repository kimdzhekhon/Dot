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

    return AppResponsiveLayout(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Dot (Central Figure)
          GestureDetector(
             onTap: dotState != DotState.idle ? _onReset : null,
             child: DotAnimation(state: dotState),
          ),

          // 2. The Result Overlay (Inside Dot if possible, or below)
          if (scanState.score != null)
             Positioned(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                     '${scanState.score}',
                     style: AppTheme.displayLarge,
                   ),
                   const SizedBox(height: 8),
                   Text(
                     scanState.message ?? '',
                     style: AppTheme.labelSmall,
                   ),
                 ],
               ),
             ),
          
          // 3. The Input (Bottom Sheet style)
          if (isIdle)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.surface),
                ),
                child: TextField(
                  controller: _textController,
                  style: AppTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Paste suspicious text...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.paste, color: AppTheme.textSecondary),
                  ),
                  onSubmitted: (_) => _onSubmit(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
