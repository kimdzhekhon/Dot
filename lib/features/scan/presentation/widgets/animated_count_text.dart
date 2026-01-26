import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedCountText extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutQuart,
      builder: (context, val, child) {
        final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
        final formatted = val.toInt().toString().replaceAllMapped(formatter, (m) => '${m[1]},');
        return Text(
          formatted,
          style: style?.copyWith(
            fontFeatures: [const FontFeature.tabularFigures()],
          ) ?? const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
