import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/presentation/providers/app_providers.dart';
import 'package:danang_smarttour/presentation/widgets/safety_badge.dart';
import 'chef_ticket_dialog.dart';

class FoodScannerScreen extends ConsumerStatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  ConsumerState<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends ConsumerState<FoodScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  Dish? _selectedDish;
  SafetyVerdict? _verdict;
  SafetyTicket? _activeTicket;
  String? _aiAnalysisText;

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo == null) return;

      setState(() {
        _isAnalyzing = true;
        _verdict = null;
        _activeTicket = null;
      });

      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);

      final vokeClient = ref.read(vokeClientProvider);
      final profile = ref.read(travelerProfileProvider);

      final aiResponse = await vokeClient.analyzeImage(
        imageBase64: base64Image,
        prompt: '''
Identify the Da Nang local dish or menu in the image.
Deconstruct hidden ingredients (stewed pork bone broth, pork lard, peanut oil, dried shrimp, fermented fish sauce).
Evaluate for tourist: Faith = ${profile.dietRule ?? 'None'}, Allergy = ${profile.allergen ?? 'None'}.
Return JSON only:
{"dish_name": "Dish name", "hidden_ingredients": "ingredients", "safety_level": "RED/YELLOW/GREEN", "reason": "concise English reason"}
''',
      );

      String detectedName = 'Mì Quảng Gà';
      if (aiResponse.success && aiResponse.jsonPayload != null) {
        detectedName = aiResponse.jsonPayload!['dish_name']?.toString() ?? 'Mì Quảng Gà';
      }

      final dishesAsync = ref.read(dishesProvider);
      final allDishes = dishesAsync.asData?.value ?? [];
      final matchedDish = allDishes.firstWhere(
        (d) => d.nameVi.toLowerCase().contains(detectedName.toLowerCase()),
        orElse: () => allDishes.isNotEmpty ? allDishes.first : const Dish(
          id: 99,
          nameVi: 'AI Detected Dish',
          hiddenIngredients: 'Decoded from VokeAPI Vision',
        ),
      );

      _evaluateDish(matchedDish, aiResponse.content);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan Error: $e')),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _evaluateDish(Dish dish, [String? aiText]) {
    final profile = ref.read(travelerProfileProvider);

    final verdict = SafetyEvaluator.evaluateDishSafety(
      dishName: dish.nameVi,
      hiddenIngredients: dish.hiddenIngredients,
      containsPork: dish.containsPork,
      containsPeanut: dish.containsPeanut,
      isSafeForHalal: dish.isSafeForHalal,
      requiresKitchenConfirmation: dish.requiresKitchenConfirmation,
      dietRule: profile.dietRule,
      allergen: profile.allergen,
      allergenSeverity: profile.allergenSeverity,
    );

    SafetyTicket? ticket;
    if (verdict.chefTicketVi != null) {
      ticket = SafetyTicket(
        userId: profile.id,
        dishId: dish.id,
        dishName: dish.nameVi,
        ticketCode: 'TICKET-DN-${DateTime.now().millisecondsSinceEpoch % 10000}',
        bilingualWarning: '${verdict.chefTicketVi}\n\n[English translation for traveler]:\n${verdict.chefTicketEn}',
        verified: true,
        createdAt: DateTime.now(),
      );
      // Persist and verify ticket
      ref.read(savedTicketsProvider.notifier).saveAndVerify(ticket);
    }

    setState(() {
      _selectedDish = dish;
      _verdict = verdict;
      _activeTicket = ticket;
      _aiAnalysisText = aiText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(travelerProfileProvider);
    final dishesAsync = ref.watch(dishesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Culinary Bodyguard Scanner'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Traveler Profile Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active Filter: ${profile.displayName} | '
                      '${profile.dietRule != null ? profile.dietRule!.toUpperCase() : "Standard Diet"} | '
                      '${profile.allergen != null ? "Allergy: " + profile.allergen! : "No Allergies"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepSea,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Camera & Gallery Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture Dish / Menu'),
                    onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from Gallery'),
                    onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Test Cases Selection Bar (Ground-Truth verification)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.touch_app, color: AppColors.goldenSand, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Select Test Dishes (Ground-Truth Cases):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  dishesAsync.when(
                    data: (dishes) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dishes.map((dish) {
                        final isSelected = _selectedDish?.id == dish.id;
                        return ChoiceChip(
                          label: Text(dish.nameVi, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => _evaluateDish(dish),
                        );
                      }).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading dishes: $err'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Loading Indicator
            if (_isAnalyzing) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryBlue),
                      SizedBox(height: 12),
                      Text(
                        'AI Vision is deconstructing hidden ingredients...',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Analysis Result & Verdict
            if (_verdict != null && _selectedDish != null && !_isAnalyzing) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _verdict!.level == SafetyLevel.red
                        ? AppColors.flagRed
                        : _verdict!.level == SafetyLevel.yellow
                            ? AppColors.flagYellow
                            : AppColors.flagGreen,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDish!.nameVi,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SafetyBadge(level: _verdict!.level),
                      ],
                    ),
                    const Divider(height: 20),

                    // Hidden ingredients
                    const Text(
                      'HIDDEN INGREDIENTS DECONSTRUCTION:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _selectedDish!.hiddenIngredients,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Safety Reason in English
                    Text(
                      _verdict!.reason,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _verdict!.level == SafetyLevel.red
                            ? AppColors.flagRed
                            : _verdict!.level == SafetyLevel.yellow
                                ? AppColors.flagYellow
                                : AppColors.flagGreen,
                        height: 1.3,
                      ),
                    ),

                    // Alternative Recommendation
                    if (_verdict!.alternativeSuggestion != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz, color: AppColors.primaryBlue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _verdict!.alternativeSuggestion!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Open Chef Ticket Button
                    if (_activeTicket != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.flagYellow,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View Bilingual Chef Dietary Ticket'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ChefTicketDialog(ticket: _activeTicket!),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
