import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/core/utils/voice_handoff_helper.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'fullscreen_chef_ticket_screen.dart';

class ChefTicketDialog extends StatelessWidget {
  final SafetyTicket ticket;

  const ChefTicketDialog({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.flagYellowBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: AppColors.flagYellow, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHEF DIETARY TICKET',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Bilingual Notice (Vietnamese + English)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Ticket Code & Verification State
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ticket ID: ${ticket.ticketCode}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        ticket.verified
                            ? Icons.verified
                            : Icons.hourglass_top,
                        size: 16,
                        color: ticket.verified
                            ? AppColors.flagGreen
                            : AppColors.flagYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.verified ? 'Verified Safe' : 'Pending Verification',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ticket.verified
                              ? AppColors.flagGreen
                              : AppColors.flagYellow,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bilingual Vietnamese message for local kitchen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.flagYellowBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.flagYellow, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🇻🇳 ', style: TextStyle(fontSize: 16)),
                      Text(
                        'SHOW THIS TO LOCAL KITCHEN / CHEF:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.flagYellow,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.bilingualWarning,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Action Row: Fullscreen Card + Voice Speech
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.fullscreen, size: 20),
                    label: const Text('Fullscreen Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      FullscreenChefTicketScreen.open(context, ticket);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.flagGreenBackground,
                    foregroundColor: AppColors.flagGreen,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.volume_up_rounded),
                  tooltip: 'Speak Vietnamese',
                  onPressed: () {
                    VoiceHandoffHelper.speakVietnamese(ticket.bilingualWarning);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Playing Vietnamese voice note for cook...')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Note'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ticket.bilingualWarning));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied chef note to clipboard!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it / Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
