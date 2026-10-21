import 'package:flutter/material.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';

class CrowdIndicator extends StatelessWidget {
  final bool isOverloaded;
  final VoidCallback? onRerouteTap;

  const CrowdIndicator({
    super.key,
    required this.isOverloaded,
    this.onRerouteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOverloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.flagGreenBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: AppColors.flagGreen, size: 14),
            SizedBox(width: 4),
            Text(
              'Crowd: Low / Clear',
              style: TextStyle(
                color: AppColors.flagGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.flagRedBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.flagRed.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.flagRed, size: 14),
          const SizedBox(width: 4),
          const Text(
            'Overcrowded / Peak Hour',
            style: TextStyle(
              color: AppColors.flagRed,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onRerouteTap != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRerouteTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.flagRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Reroute ➔',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
