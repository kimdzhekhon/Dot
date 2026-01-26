import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/features/scan/presentation/scan_screen.dart';
import 'package:dot/features/scan/presentation/url_extract_result_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/url-extract-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return UrlExtractResultScreen(
            originalText: extra['text'] as String,
            extractedUrls: extra['urls'] as List<String>,
          );
        },
      ),
    ],
  );
});
