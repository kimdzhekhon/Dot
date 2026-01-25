import 'package:flutter/material.dart';
import 'package:dot/core/design_system/app_theme.dart';

class AppResponsiveLayout extends StatelessWidget {
  final Widget child;

  const AppResponsiveLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Mobile-first aesthetic on large screens
          child: child,
        ),
      ),
    );
  }
}
