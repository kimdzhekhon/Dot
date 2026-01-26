import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/app/router.dart';
import 'package:dot/app/bootstrap.dart';
import 'package:dot/core/design_system/app_theme.dart';
import 'package:go_router/go_router.dart';

class DotApp extends ConsumerWidget {
  const DotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final bootstrap = ref.watch(bootstrapProvider);

    return bootstrap.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, stack) => _buildApp(router), // Continue even on error
      data: (_) => _buildApp(router),
    );
  }

  Widget _buildApp(GoRouter router) {
    return MaterialApp.router(
      title: 'DOT',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
