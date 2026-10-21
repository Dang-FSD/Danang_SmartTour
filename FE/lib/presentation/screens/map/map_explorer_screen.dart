import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/core/constants/danang_constants.dart';
import 'package:danang_smarttour/core/utils/deeplink_helper.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/presentation/providers/app_providers.dart';
import 'package:danang_smarttour/presentation/widgets/safety_badge.dart';

class MapExplorerScreen extends ConsumerStatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  ConsumerState<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends ConsumerState<MapExplorerScreen> {
  final MapController _mapController = MapController();
  Attraction? _selectedAttraction;

  void _onSelectAttraction(Attraction attraction) {
    setState(() {
      _selectedAttraction = attraction;
    });
    _mapController.move(attraction.coordinates, 14.5);
  }

  void _autoRerouteFromDragonBridge(List<Attraction> all) {
    // Find alternative spot (Non Nuoc Stone Village - ID 3)
    final alt = all.firstWhere(
      (a) => a.id == 3,
      orElse: () => all.first,
    );
    _onSelectAttraction(alt);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryBlue,
        content: Text('Smart Routing: You have been rerouted to Non Nuoc Stone Carving Village!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attractionsAsync = ref.watch(attractionsProvider);
    final profile = ref.watch(travelerProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Da Nang Map (OpenStreetMap)'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: attractionsAsync.when(
        data: (attractions) {
          final markers = attractions.map((attraction) {
            final isSelected = _selectedAttraction?.id == attraction.id;
            final isOverloaded = attraction.isOverloaded;

            return Marker(
              point: attraction.coordinates,
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _onSelectAttraction(attraction),
                child: Container(
                  decoration: BoxDecoration(
                    color: isOverloaded
                        ? AppColors.flagRed
                        : attraction.category == 'sport'
                            ? AppColors.coralSun
                            : AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.yellowAccent : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isOverloaded
                        ? Icons.warning_amber_rounded
                        : attraction.category == 'sport'
                            ? Icons.fitness_center
                            : Icons.temple_buddhist,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              // OpenStreetMap render via flutter_map
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: DanangConstants.centerDaNang,
                  initialZoom: DanangConstants.defaultZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate: DanangConstants.osmTileUrl,
                    userAgentPackageName: 'com.danang.smarttour',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Overload Alert Banner
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.traffic, color: AppColors.flagRed, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Dragon Bridge: Congested (Fire-Breathing Hour)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.flagRed,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.flagRedBackground,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: () => _autoRerouteFromDragonBridge(attractions),
                        child: const Text(
                          'Reroute ➔',
                          style: TextStyle(
                            color: AppColors.flagRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sheet Detail Card
              if (_selectedAttraction != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildAttractionDetailCard(_selectedAttraction!, profile),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Map error: $err')),
      ),
    );
  }

  Widget _buildAttractionDetailCard(Attraction attraction, dynamic profile) {
    // Physical & crowd safety evaluation
    final verdict = SafetyEvaluator.evaluateAttractionSafety(
      attractionName: attraction.nameVi,
      difficulty: attraction.difficulty,
      isOverloaded: attraction.isOverloaded,
      medicalCondition: profile.medicalCondition,
      fitnessLevel: profile.fitnessLevel,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  attraction.nameVi,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SafetyBadge(level: verdict.level),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            attraction.description ?? '',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Safety reason in English
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              verdict.reason,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: verdict.level == SafetyLevel.red
                    ? AppColors.flagRed
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Turn-by-turn Navigation Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Turn-by-turn Navigation'),
                  onPressed: () {
                    DeeplinkHelper.launchNavigation(
                      latitude: attraction.latitude,
                      longitude: attraction.longitude,
                      label: attraction.nameVi,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedAttraction = null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
