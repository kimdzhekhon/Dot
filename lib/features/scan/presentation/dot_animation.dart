import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:dot/core/design_system/app_theme.dart';
import 'package:lottie/lottie.dart';

enum DotState {
  idle,
  analyzing,
  safe,
  dangerous,
  warning,
}

class DotAnimation extends StatefulWidget {
  final DotState state;
  final double size;

  const DotAnimation({
    super.key,
    required this.state,
    this.size = 200,
  });

  @override
  State<DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<DotAnimation> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color _getColorForState(DotState state) {
    switch (state) {
      case DotState.idle:
        return AppTheme.primary;
      case DotState.analyzing:
        return AppTheme.analyzing;
      case DotState.safe:
        return AppTheme.safe;
      case DotState.dangerous:
        return AppTheme.dangerous;
      case DotState.warning:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForState(widget.state);
    
    // Result States use Lottie
    if (widget.state == DotState.safe) {
      return Lottie.asset(
        'assets/animation/Success Check.json',
        width: widget.size,
        height: widget.size,
        repeat: false,
      );
    }
    
    if (widget.state == DotState.warning) {
      return Lottie.asset(
        'assets/animation/Alert.json',
        width: widget.size,
        height: widget.size,
        repeat: false,
      );
    }

    if (widget.state == DotState.dangerous) {
      return Lottie.asset(
        'assets/animation/Failed.json',
        width: widget.size,
        height: widget.size,
        repeat: false,
      );
    }


    // Analyzing or Idle uses the custom dot animation
    final isAnalyzing = widget.state == DotState.analyzing;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.1);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          // Core Dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          // Rotating Ring (Only when analyzing)
          if (isAnalyzing)
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Container(
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: color.withValues(alpha: 0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

