import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/core/constants/danang_constants.dart';
import 'package:danang_smarttour/core/utils/deeplink_helper.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/presentation/providers/app_providers.dart';
import 'package:danang_smarttour/presentation/widgets/safety_badge.dart';
import 'widgets/heritage_story_sheet.dart';

enum CrowdScenario {
  weekendFireShow,
  beachRedAlert,
  normal,
}

class MapExplorerScreen extends ConsumerStatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  ConsumerState<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends ConsumerState<MapExplorerScreen> {
  final MapController _mapController = MapController();
  Attraction? _selectedAttraction;
  CrowdScenario _currentScenario = CrowdScenario.weekendFireShow;
  bool _isRerouteActive = false;

  // Polyline coordinates from Dragon Bridge to Non Nuoc Stone Village via coastal Vo Nguyen Giap / Truong Sa
  static const List<LatLng> _reroutePolylinePoints = [
    LatLng(16.0610, 108.2272), // Cầu Rồng
    LatLng(16.0590, 108.2370), // Đường Nguyễn Văn Thoại
    LatLng(16.0580, 108.2450), // Ngã ba Võ Nguyên Giáp
    LatLng(16.0350, 108.2520), // Dọc bãi biển Mỹ Khê - Ngũ Hành Sơn
    LatLng(16.0150, 108.2590), // Đường Trường Sa
    LatLng(16.0028, 108.2639), // Làng đá Mỹ nghệ Non Nước
  ];

  void _onSelectAttraction(Attraction attraction) {
    setState(() {
      _selectedAttraction = attraction;
    });
    _mapController.move(attraction.coordinates, 14.5);
  }

  void _executeSmartReroute(List<Attraction> all) {
    setState(() {
      _isRerouteActive = true;
    });

    // Find destination: Non Nuoc Stone Village (ID 3)
    final alt = all.firstWhere(
      (a) => a.id == 3,
      orElse: () => all.first,
    );

    _onSelectAttraction(alt);
    _mapController.move(const LatLng(16.0320, 108.2450), 12.8);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryBlue,
        duration: Duration(seconds: 4),
        content: Row(
          children: [
            Icon(Icons.alt_route, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '🔄 Smart Routing: Diverted to Non Nuoc Stone Carving Village (-42 mins saved, supporting SDG 8 local artisans)!',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
        title: const Text('Da Nang Map Explorer (OpenStreetMap)'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset Center',
            icon: const Icon(Icons.my_location),
            onPressed: () => _mapController.move(DanangConstants.centerDaNang, DanangConstants.defaultZoom),
          ),
        ],
      ),
      body: attractionsAsync.when(
        data: (attractions) {
          final isDragonCongested = _currentScenario == CrowdScenario.weekendFireShow;
          final isBeachRisky = _currentScenario == CrowdScenario.beachRedAlert;

          // Build markers
          final markers = attractions.map((attraction) {
            final isSelected = _selectedAttraction?.id == attraction.id;
            bool isOverloaded = attraction.isOverloaded;

            if (attraction.id == 2) {
              isOverloaded = isDragonCongested;
            } else if (attraction.id == 4) {
              isOverloaded = isBeachRisky;
            }

            return Marker(
              point: attraction.coordinates,
              width: isSelected ? 48 : 42,
              height: isSelected ? 48 : 42,
              child: GestureDetector(
                onTap: () => _onSelectAttraction(attraction),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: isOverloaded
                        ? AppColors.flagRed
                        : attraction.category == 'sport'
                            ? AppColors.coralSun
                            : AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.amberAccent : Colors.white,
                      width: isSelected ? 3.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isOverloaded ? AppColors.flagRed : Colors.black).withValues(alpha: 0.35),
                        blurRadius: isSelected ? 10 : 6,
                        offset: const Offset(0, 3),
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
                    size: isSelected ? 22 : 18,
                  ),
                ),
              ),
            );
          }).toList();

          // Build circles for congested zones
          final List<CircleMarker> crowdCircles = [];
          if (isDragonCongested) {
            crowdCircles.add(
              CircleMarker(
                point: DanangConstants.dragonBridge,
                color: AppColors.flagRed.withValues(alpha: 0.22),
                borderColor: AppColors.flagRed,
                borderStrokeWidth: 2,
                radius: 40,
              ),
            );
          }
          if (isBeachRisky) {
            crowdCircles.add(
              CircleMarker(
                point: DanangConstants.myKheBeach,
                color: AppColors.coralSun.withValues(alpha: 0.25),
                borderColor: AppColors.coralSun,
                borderStrokeWidth: 2,
                radius: 40,
              ),
            );
          }

          // Build polylines for active rerouting
          final List<Polyline> polylines = [];
          if (_isRerouteActive || isDragonCongested) {
            polylines.add(
              Polyline(
                points: _reroutePolylinePoints,
                color: AppColors.primaryBlue,
                strokeWidth: 4.5,
              ),
            );
          }

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
                  CircleLayer(circles: crowdCircles),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Simulation Scenario Control Panel (Top)
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    // Scenario Selector Chips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: AppColors.primaryBlue, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Simulation:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('🔴 Dragon Bridge Peak (450%)', style: TextStyle(fontSize: 11)),
                                    selected: _currentScenario == CrowdScenario.weekendFireShow,
                                    selectedColor: AppColors.flagRedBackground,
                                    labelStyle: TextStyle(
                                      color: _currentScenario == CrowdScenario.weekendFireShow ? AppColors.flagRed : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _currentScenario = CrowdScenario.weekendFireShow;
                                          _isRerouteActive = true;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: const Text('🌊 High Waves at My Khe', style: TextStyle(fontSize: 11)),
                                    selected: _currentScenario == CrowdScenario.beachRedAlert,
                                    selectedColor: const Color(0xFFFFECE5),
                                    labelStyle: TextStyle(
                                      color: _currentScenario == CrowdScenario.beachRedAlert ? AppColors.coralSun : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _currentScenario = CrowdScenario.beachRedAlert;
                                          _isRerouteActive = false;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: const Text('🟢 Normal Traffic', style: TextStyle(fontSize: 11)),
                                    selected: _currentScenario == CrowdScenario.normal,
                                    selectedColor: AppColors.flagGreenBackground,
                                    labelStyle: TextStyle(
                                      color: _currentScenario == CrowdScenario.normal ? AppColors.flagGreen : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _currentScenario = CrowdScenario.normal;
                                          _isRerouteActive = false;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Alert Banner: Dragon Bridge
                    if (isDragonCongested)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.flagRed.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(color: AppColors.flagRed.withValues(alpha: 0.15), blurRadius: 10),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.traffic, color: AppColors.flagRed, size: 22),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dragon Bridge: Overcrowded (450% Peak)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.flagRed,
                                    ),
                                  ),
                                  Text(
                                    'Bottleneck >45 mins. Suggested: Non Nuoc Stone Village.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(80, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _executeSmartReroute(attractions),
                              child: const Text('Reroute ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    // Active Alert Banner: Beach Wave Alert
                    if (isBeachRisky)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.coralSun.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(color: AppColors.coralSun.withValues(alpha: 0.15), blurRadius: 10),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.waves, color: AppColors.coralSun, size: 22),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'High Waves & Rip Currents at My Khe',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.coralSun,
                                    ),
                                  ),
                                  Text(
                                    'Unsafe for SUP/swimming. Suggested: Cham Museum.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(80, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                final cham = attractions.firstWhere((a) => a.id == 6, orElse: () => attractions.first);
                                _onSelectAttraction(cham);
                              },
                              child: const Text('View Museum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                  ],
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
      isOverloaded: attraction.id == 2
          ? (_currentScenario == CrowdScenario.weekendFireShow)
          : (attraction.id == 4 ? (_currentScenario == CrowdScenario.beachRedAlert) : attraction.isOverloaded),
      medicalCondition: profile.medicalCondition,
      fitnessLevel: profile.fitnessLevel,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  verdict.level == SafetyLevel.red
                      ? Icons.error_outline
                      : (verdict.level == SafetyLevel.yellow ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                  size: 16,
                  color: verdict.level == SafetyLevel.red
                      ? AppColors.flagRed
                      : (verdict.level == SafetyLevel.yellow ? AppColors.flagYellow : AppColors.flagGreen),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    verdict.reason,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: verdict.level == SafetyLevel.red
                          ? AppColors.flagRed
                          : (verdict.level == SafetyLevel.yellow ? const Color(0xFF856404) : AppColors.flagGreen),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dual Action Row: Cultural Story + Turn-by-Turn Navigation
          Row(
            children: [
              // Cultural Story Button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.goldenSand, width: 1.5),
                    backgroundColor: const Color(0xFFFFFDF9),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.temple_buddhist, size: 18, color: Color(0xFF9A6B00)),
                  label: const Text(
                    'Heritage Story & Rules',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A6B00)),
                  ),
                  onPressed: () {
                    HeritageStorySheet.show(context, attraction);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Turn-by-turn Navigation Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navigation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    DeeplinkHelper.launchNavigation(
                      latitude: attraction.latitude,
                      longitude: attraction.longitude,
                      label: attraction.nameVi,
                    );
                  },
                ),
              ),
              const SizedBox(width: 4),
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
