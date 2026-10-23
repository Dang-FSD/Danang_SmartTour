import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/core/utils/voice_handoff_helper.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';

class FullscreenChefTicketScreen extends StatefulWidget {
  final SafetyTicket ticket;

  const FullscreenChefTicketScreen({
    super.key,
    required this.ticket,
  });

  static void open(BuildContext context, SafetyTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenChefTicketScreen(ticket: ticket),
      ),
    );
  }

  @override
  State<FullscreenChefTicketScreen> createState() => _FullscreenChefTicketScreenState();
}

class _FullscreenChefTicketScreenState extends State<FullscreenChefTicketScreen> {
  bool _isPlayingVoice = false;

  void _speakWarning() {
    setState(() => _isPlayingVoice = true);
    VoiceHandoffHelper.speakVietnamese(widget.ticket.bilingualWarning);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isPlayingVoice = false);
    });
  }

  @override
  void dispose() {
    VoiceHandoffHelper.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB), // High-contrast daylight yellow
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
        foregroundColor: const Color(0xFF78350F),
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text(
              'CHEF DIETARY CARD',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice banner: Bilingual instruction
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.flagRed,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.flagRed.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'SHOW THIS SCREEN TO THE LOCAL CHEF / VENDOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Giant Vietnamese Text Display for Street Cooks to Read
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🇻🇳 ', style: TextStyle(fontSize: 22)),
                            Text(
                              'GỬI CHỦ QUÁN / ĐẦU BẾP:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.ticket.bilingualWarning,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(thickness: 1.5, color: Color(0xFFFDE68A)),
                        const SizedBox(height: 12),

                        // English subtitle for tourist understanding
                        Row(
                          children: [
                            const Text('🇬🇧 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                widget.ticket.dietaryWarningEn ?? 'Special dietary warning for kitchen staff',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Ticket ID & Verified stamp
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TICKET ID: ${widget.ticket.ticketCode}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    widget.ticket.verified ? Icons.verified : Icons.hourglass_top,
                                    size: 16,
                                    color: widget.ticket.verified ? AppColors.flagGreen : AppColors.flagYellow,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.ticket.verified ? 'VERIFIED' : 'PENDING',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: widget.ticket.verified ? AppColors.flagGreen : AppColors.flagYellow,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Toolbar: Audio Speech & Copy Note
              Row(
                children: [
                  // Audio Speech Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlayingVoice ? const Color(0xFF10B981) : const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      icon: Icon(_isPlayingVoice ? Icons.volume_up : Icons.record_voice_over, size: 24),
                      label: Text(
                        _isPlayingVoice ? 'Playing Audio...' : '🔊 Speak Vietnamese (Audio)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _speakWarning,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Copy Note Button
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.copy, color: Color(0xFF78350F)),
                    tooltip: 'Copy Note',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.ticket.bilingualWarning));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied chef note to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
