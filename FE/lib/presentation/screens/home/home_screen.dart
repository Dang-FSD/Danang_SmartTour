import 'package:flutter/material.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/presentation/screens/scanner/food_scanner_screen.dart';
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

  final List<Widget> _screens = const [
    _HomeDashboardTab(),
    FoodScannerScreen(),
    MapExplorerScreen(),
    ItineraryScreen(),
    ProfileSetupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.primaryBlue.withOpacity(0.15),
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
            label: 'Map',
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

class _HomeDashboardTab extends StatelessWidget {
  const _HomeDashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DaNang SmartTour AI'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
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
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
                    'AI-powered hidden ingredient analysis • Dynamic crowd rerouting at Dragon Bridge • Inclusive accessibility for international tourists',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                    subtitle: 'Overtourism Routing',
                    value: '30% Divert',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'SDG 10',
                    subtitle: 'Inclusive Tourism',
                    value: '100% Verified',
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
              'Core Features',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.qr_code_scanner,
              title: 'Culinary Bodyguard Scanner',
              subtitle: 'Decodes hidden pork broth for Halal tourists & peanut oil for food allergies.',
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.alt_route,
              title: 'Crowd-Aware Dynamic Routing',
              subtitle: 'Automatically diverts visitors away from congested Dragon Bridge to nearby cultural gems.',
              color: AppColors.coralSun,
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.receipt_long,
              title: 'Bilingual Chef Dietary Ticket',
              subtitle: 'Generates Vietnamese-English cards with verifiable codes to show local street chefs.',
              color: AppColors.goldenSand,
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
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
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
        ],
      ),
    );
  }
}
