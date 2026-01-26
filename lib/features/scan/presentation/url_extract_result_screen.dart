
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/core/design_system/app_theme.dart';
import 'package:dot/core/design_system/app_responsive_layout.dart';
import 'package:dot/core/design_system/app_button.dart';
import 'package:dot/features/scan/presentation/scan_controller.dart';
import 'package:go_router/go_router.dart';

class UrlExtractResultScreen extends ConsumerWidget {
  final String originalText;
  final List<String> extractedUrls;

  const UrlExtractResultScreen({
    super.key,
    required this.originalText,
    required this.extractedUrls,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppResponsiveLayout(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.left_chevron, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'URL 추출 결과',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '원본 텍스트',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    originalText,
                    style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '추출된 URL (${extractedUrls.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: extractedUrls.isEmpty
                      ? const Center(
                          child: Text(
                            '추출된 URL이 없습니다.',
                            style: TextStyle(color: Colors.black38),
                          ),
                        )
                      : ListView.separated(
                          itemCount: extractedUrls.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final url = extractedUrls[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.link, color: AppTheme.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      url,
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: '위험도 분석하기',
                  onPressed: () {
                    context.pop(); // Go back
                    ref.read(scanProvider.notifier).analyzeText(originalText);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
