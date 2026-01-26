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
    // Listen to bootstrap to trigger side effects if needed, but don't block
    ref.listen(bootstrapProvider, (_, __) {});

    return MaterialApp.router(
      title: 'DOT',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
