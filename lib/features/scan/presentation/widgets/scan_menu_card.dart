import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dot/core/design_system/app_theme.dart';
import 'package:dot/features/scan/domain/scan_type.dart';

class ScanMenuCard extends StatelessWidget {
  final String label;
  final String? description;
  final ScanType type;
  final IconData icon;
  final VoidCallback onTap;

  const ScanMenuCard({
    super.key,
    required this.label,
    this.description,
    required this.type,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
