import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/presentation/providers/app_providers.dart';
import 'package:danang_smarttour/presentation/screens/scanner/food_scanner_screen.dart';
import 'package:danang_smarttour/presentation/screens/scanner/fullscreen_chef_ticket_screen.dart';
import 'package:danang_smarttour/presentation/screens/map/map_explorer_screen.dart';
import 'package:danang_smarttour/presentation/screens/itinerary/itinerary_screen.dart';
import 'package:danang_smarttour/presentation/screens/profile/profile_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeDashboardTab(onNavigate: _navigateToTab),
      const FoodScannerScreen(),
      const MapExplorerScreen(),
      const ItineraryScreen(),
      const ProfileSetupScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primaryBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.primaryBlue),
            label: 'AI Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primaryBlue),
            label: 'Map Explorer',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route),
            selectedIcon: Icon(Icons.alt_route, color: AppColors.primaryBlue),
            label: 'Itinerary',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primaryBlue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardTab extends ConsumerWidget {
  final void Function(int) onNavigate;

  const _HomeDashboardTab({required this.onNavigate});

  void _openQuickChefCard(BuildContext context, dynamic profile) {
    String viWarning;
    String enWarning;

    if (profile.dietRule == 'halal') {
      viWarning = 'TÔI LÀ NGƯỜI HỒI GIÁO (HALAL). XIN TUYỆT ĐỐI KHÔNG DÙNG THỊT HEO, MỠ HEO, NƯỚC HẦM XƯƠNG HEO HOẶC RƯỢU NẤU ĂN TRONG MÓN NÀY.';
      enWarning = 'I am Muslim (Halal). Please DO NOT use pork, lard, pork bone broth, or cooking wine.';
    } else if (profile.allergen == 'peanut') {
      viWarning = 'TÔI BỊ DỊ ỨNG ĐẬU PHỘNG (LẠC) CỰC KỲ NẶNG CÓ THỂ NGUY HIỂM TÍNH MẠNG! XIN ĐỪNG CHO ĐẬU PHỘNG HOẶC DẦU PHỘNG VÀO MÓN VÀ NƯỚC CHẤM.';
      enWarning = 'Severe Peanut Allergy! Please ensure ZERO peanuts, peanut oil, or cross-contact.';
    } else if (profile.allergen == 'seafood') {
      viWarning = 'TÔI BỊ DỊ ỨNG HẢI SẢN (TÔM, CUA, CÁ, MỰC) NẶNG! XIN KHÔNG DÙNG HẢI SẢN VÀ NƯỚC MẮM CỐT.';
      enWarning = 'Severe Seafood Allergy! Please do not use shrimp, crab, fish, squid, or raw fish sauce.';
    } else if (profile.dietRule == 'vegan' || profile.dietRule == 'vegetarian') {
      viWarning = 'TÔI ĂN CHAY THUẦN (VEGAN). XIN TUYỆT ĐỐI KHÔNG DÙNG THỊT, HẢI SẢN, NƯỚC MẮM CÁ HOẶC MỠ ĐỘNG VẬT.';
      enWarning = 'Strict Vegetarian (Vegan). No meat, fish sauce, seafood, or animal fat.';
    } else {
      viWarning = 'XIN CHÀO ĐẦU BẾP! TÔI CÓ YÊU CẦU ĐẶC BIỆT VỀ DINH DƯỠNG VÀ AN TOÀN SỨC KHỎE. XIN HỖ TRỢ NẤU THANH ĐẠM VÀ AN TOÀN.';
      enWarning = 'Special dietary requirements. Please prepare food mildly and safely.';
    }

    final ticket = SafetyTicket(
      id: 999,
      userId: profile.id,
      ticketCode: 'EMERGENCY-CHEF-CARD',
      dietaryWarningEn: enWarning,
      bilingualWarning: viWarning,
      verified: true,
      createdAt: DateTime.now(),
    );

    FullscreenChefTicketScreen.open(context, ticket);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(travelerProfileProvider);
    final activeItinerary = ref.watch(activeItineraryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DaNang SmartTour AI'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Traveler Profile',
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.primaryBlue),
            onPressed: () => onNavigate(4),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deepSea, AppColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🛡️ DUAL-LAYER PROTECTION ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onNavigate(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            profile.displayName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Explore Da Nang\nSafely & Authentically',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-powered hidden allergen decoding • Dynamic crowd rerouting at Dragon Bridge • Inclusive accessibility for international tourists',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Emergency Quick Chef Dietary Card (SDG 3 & 10)
            GestureDetector(
              onTap: () => _openQuickChefCard(context, profile),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'EMERGENCY CHEF DIETARY CARD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB45309),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TAP TO SHOW',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.allergen != null
                                ? 'Allergy: ${profile.allergen!.toUpperCase()} • Show giant card to local cook'
                                : (profile.dietRule != null
                                    ? 'Diet: ${profile.dietRule!.toUpperCase()} • Show card to local cook'
                                    : 'Tap to show bilingual dietary card to kitchen staff'),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.fullscreen, color: Color(0xFF92400E), size: 26),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Itinerary Tracker (If exists)
            if (activeItinerary != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.08), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.navigation, color: AppColors.primaryBlue, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'ACTIVE SMART ITINERARY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.flagGreenBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VERIFIED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.flagGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeItinerary.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activeItinerary.stops.length} stops • Objective: ${activeItinerary.objective.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(double.infinity, 38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View Full Itinerary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => onNavigate(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sustainable Impact (SDGs)
            const Text(
              'Sustainable Development Goals (SDGs)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'SDG 11',
                    subtitle: 'Crowd Routing',
                    value: '-42 mins',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'SDG 10',
                    subtitle: 'Inclusive Tourism',
                    value: '100% Safe',
                    color: AppColors.flagGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'SDG 8',
                    subtitle: 'Local Craft Villages',
                    value: 'Non Nuoc Village',
                    color: AppColors.goldenSand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Key Core Features
            const Text(
              'Core Capabilities',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.qr_code_scanner,
              title: 'AI Culinary Bodyguard Scanner',
              subtitle: 'Decodes hidden pork broth for Halal tourists & peanut oil for food allergies.',
              color: AppColors.primaryBlue,
              onTap: () => onNavigate(1),
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.map,
              title: 'Crowd-Aware Map (OpenStreetMap)',
              subtitle: 'Auto-diverts away from congested Dragon Bridge to Non Nuoc Village with cultural guide.',
              color: AppColors.coralSun,
              onTap: () => onNavigate(2),
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.alt_route,
              title: 'Adaptive AI Multi-Trip Planner',
              subtitle: '7 Agent tools orchestrating Cultural, Adventure & Food tours with Zero False-Safety.',
              color: AppColors.goldenSand,
              onTap: () => onNavigate(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
