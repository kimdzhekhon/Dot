import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/features/scan/presentation/scan_providers.dart';
import 'package:dot/features/scan/presentation/widgets/animated_count_text.dart';

class ScanStatsHeader extends ConsumerWidget {
  const ScanStatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(tableCountsProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 36,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF4A80F0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A80F0), Color(0xFF3B6ADB)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '실시간 안전 데이터 현황',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '안전한 통신을 유지 중입니다',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildStatRow('스팸 리스트', (counts['Message_Spam'] ?? 0), CupertinoIcons.ant_fill),
          const SizedBox(height: 16),
          _buildStatRow('차단 웹사이트', (counts['Web_Blacklist'] ?? 0), CupertinoIcons.shield_fill),
          const SizedBox(height: 16),
          _buildStatRow('기관 정보', (counts['contact_list'] ?? 0), CupertinoIcons.building_2_fill),
          const SizedBox(height: 16),
          _buildStatRow('안전 웹사이트', (counts['Web_Whitelist'] ?? 0), CupertinoIcons.checkmark_shield_fill),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int targetValue, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        AnimatedCountText(value: targetValue),
        const SizedBox(width: 4),
        const Text(
          '개',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
