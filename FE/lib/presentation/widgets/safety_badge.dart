import 'package:flutter/material.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';

class SafetyBadge extends StatelessWidget {
  final SafetyLevel level;
  final bool showLabel;

  const SafetyBadge({
    super.key,
    required this.level,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String text;

    switch (level) {
      case SafetyLevel.red:
        bg = AppColors.flagRedBackground;
        fg = AppColors.flagRed;
        icon = Icons.cancel;
        text = 'RED FLAG (HAZARD)';
        break;
      case SafetyLevel.yellow:
        bg = AppColors.flagYellowBackground;
        fg = AppColors.flagYellow;
        icon = Icons.warning_amber_rounded;
        text = 'YELLOW FLAG (CAUTION)';
        break;
      case SafetyLevel.green:
        bg = AppColors.flagGreenBackground;
        fg = AppColors.flagGreen;
        icon = Icons.check_circle;
        text = 'GREEN FLAG (SAFE)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
