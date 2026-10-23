import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/core/utils/dish_matcher.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/presentation/providers/app_providers.dart';
import 'package:danang_smarttour/presentation/widgets/safety_badge.dart';
import 'chef_ticket_dialog.dart';
import 'fullscreen_chef_ticket_screen.dart';

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
  String? _aiActionAdvice;
  String? _askWaiterVi;
  String? _askWaiterEn;
  Uint8List? _scannedImageBytes;
  String? _scannedImageName;
  MatchResult? _lastMatchResult;
  String? _apiWarning;

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo == null) return;

      final bytes = await photo.readAsBytes();

      setState(() {
        _isAnalyzing = true;
        _verdict = null;
        _activeTicket = null;
        _scannedImageBytes = bytes;
        _scannedImageName = photo.name;
        _lastMatchResult = null;
        _apiWarning = null;
      });

      final base64Image = base64Encode(bytes);
      final vokeClient = ref.read(vokeClientProvider);
      final profile = ref.read(travelerProfileProvider);

      final aiResponse = await vokeClient.analyzeImage(
        imageBase64: base64Image,
        prompt: '''
You are a Senior Vietnamese Culinary Expert & Food Safety Inspector in Da Nang.
Da Nang restaurants serve both Central local dishes AND regional Vietnamese classics (Bún chả Hà Nội, Phở Bò, Cơm Tấm, Bún bò Huế, Bún đậu mắm tôm, Bánh Mì Thịt).
OBJECTIVELY identify the dish from visual features. NEVER force a non-Da Nang dish into a Da Nang specialty.

CRITICAL DISCRIMINATION RULE:
- If you see a crispy baguette stuffed with pate, cold cuts, cilantro, pickled carrots: It is Bánh Mì Thịt (Contains PORK pate/ham, GLUTEN, EGG. FORBIDDEN FOR HALAL/VEGAN).
- If you see grilled pork patties / grilled pork belly in amber dipping sauce with separate white vermicelli and perilla herbs: It is Bún Chả Hà Nội (Contains PORK, FISH SAUCE. FORBIDDEN FOR HALAL/VEGAN). It is NOT Bún chả cá!
- If you see fried or steamed fish patties inside a bowl of reddish tomato/pineapple/pumpkin soup: It is Bún Chả Cá Đà Nẵng.

Active Traveler Profile:
- Faith: ${profile.dietRule ?? 'None'}
- Allergy: ${profile.allergen ?? 'None'} (${profile.allergenSeverity ?? 'N/A'})

Return JSON ONLY matching this schema (no thoughts, no code blocks):
{
  "dish_name": "Exact Vietnamese Name (e.g. Bánh Mì Thịt, Bún Chả Hà Nội, Phở Bò, Bánh Xèo, Mì Quảng)",
  "dish_name_en": "Accurate English Name",
  "confidence": 0.95,
  "hidden_ingredients": "stewed bone broth, pork lard, peanut oil, pate...",
  "contains_pork": true,
  "contains_peanut": false,
  "contains_seafood": false,
  "is_safe_for_halal": false,
  "action_advice": "1-2 assertive sentences instructing the tourist what to do.",
  "ask_waiter_vi": "Direct Vietnamese phrase to show the waiter.",
  "ask_waiter_en": "English meaning of the question."
}
''',
      );

      String detectedName = '';
      if (aiResponse.success && aiResponse.jsonPayload != null) {
        final payload = aiResponse.jsonPayload!;
        detectedName = payload['dish_name']?.toString() ??
            payload['dish_name_en']?.toString() ??
            '';
      } else {
        // Record API failure/warning for user awareness
        _apiWarning = aiResponse.error?.contains('401') == true
            ? 'VokeAPI key authentication error (HTTP 401). Using Smart Local Vision Heuristics.'
            : (aiResponse.error != null ? 'Cloud AI timeout/notice: ${aiResponse.error}' : null);
      }

      final dishesAsync = ref.read(dishesProvider);
      final allDishes = dishesAsync.asData?.value ?? [];

      final matchResult = DishMatcher.matchOrConstructDish(
        detectedRawName: detectedName.isNotEmpty ? detectedName : aiResponse.content,
        availableDishes: allDishes,
        aiPayload: aiResponse.jsonPayload,
        fileNameHint: photo.name,
      );

      _lastMatchResult = matchResult;
      if (matchResult.dish.id != 0) {
        _evaluateDish(matchResult.dish, aiResponse.jsonPayload);
      } else {
        setState(() {
          _selectedDish = null;
          _verdict = null;
          _activeTicket = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _evaluateDish(Dish dish, [Map<String, dynamic>? aiPayload]) {
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

    String actionAdvice;
    String askWaiterVi;
    String askWaiterEn;

    if (aiPayload != null && aiPayload['action_advice'] != null) {
      actionAdvice = aiPayload['action_advice'].toString();
      askWaiterVi = aiPayload['ask_waiter_vi']?.toString() ?? 'Món này có dùng mỡ heo hoặc đậu phộng không?';
      askWaiterEn = aiPayload['ask_waiter_en']?.toString() ?? 'Does this dish contain pork lard or peanuts?';
    } else {
      if (verdict.level == SafetyLevel.red) {
        actionAdvice = 'STRICT HAZARD: Do not consume. Contains ingredients violating your safety restrictions.';
        askWaiterVi = 'Quán ơi, có món nào hoàn toàn không dùng thịt heo hoặc mỡ lợn không ạ?';
        askWaiterEn = 'Does the restaurant have any dishes made without pork or animal lard?';
      } else if (verdict.level == SafetyLevel.yellow) {
        actionAdvice = 'ORDER WITH PRECAUTIONS: Customization required. Present the Chef Ticket below to the kitchen.';
        askWaiterVi = 'Làm ơn cho tôi một phần không cho đậu phộng/lạc và không dùng dầu phộng nhé!';
        askWaiterEn = 'Please prepare mine strictly without peanuts and without peanut oil!';
      } else {
        actionAdvice = '100% SAFE: Verified compliant with your profile. Enjoy your authentic dining!';
        askWaiterVi = 'Làm cho tôi món này bình thường nhé, cảm ơn quán!';
        askWaiterEn = 'Please prepare one standard portion, thank you!';
      }
    }

    setState(() {
      _selectedDish = dish;
      _verdict = verdict;
      _activeTicket = ticket;
      _aiActionAdvice = actionAdvice;
      _askWaiterVi = askWaiterVi;
      _askWaiterEn = askWaiterEn;
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

            // Image Preview Box (Visual Confirmation of Scanned Image)
            if (_apiWarning != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _apiWarning!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_scannedImageBytes != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _scannedImageBytes!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _lastMatchResult?.dish.id == 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle,
                                color: _lastMatchResult?.dish.id == 0
                                    ? AppColors.flagYellow
                                    : AppColors.flagGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _lastMatchResult?.dish.id == 0
                                    ? 'Unidentified Dish'
                                    : 'Photo Analyzed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _lastMatchResult?.dish.id == 0
                                      ? Colors.orange.shade900
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _scannedImageName ?? 'Captured Dish Photo',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_lastMatchResult != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _lastMatchResult!.dish.id == 0
                                    ? Colors.red.shade50
                                    : (_lastMatchResult!.isCustomDetected
                                        ? Colors.purple.shade50
                                        : AppColors.primaryBlue.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(6),
                                border: _lastMatchResult!.dish.id == 0
                                    ? Border.all(color: Colors.red.shade200)
                                    : null,
                              ),
                              child: Text(
                                _lastMatchResult!.dish.id == 0
                                    ? '⚠️ Not recognized. Pick from test chips below.'
                                    : (_lastMatchResult!.isCustomDetected
                                        ? '✨ AI Detected: ${_lastMatchResult!.dish.nameVi}'
                                        : 'Matched: ${_lastMatchResult!.matchedKeyword} (${(_lastMatchResult!.confidenceScore * 100).toInt()}%)'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: _lastMatchResult!.dish.id == 0
                                      ? Colors.red.shade700
                                      : (_lastMatchResult!.isCustomDetected
                                          ? Colors.purple
                                          : AppColors.primaryBlue),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      tooltip: 'Clear Photo',
                      onPressed: () {
                        setState(() {
                          _scannedImageBytes = null;
                          _scannedImageName = null;
                          _lastMatchResult = null;
                          _selectedDish = null;
                          _verdict = null;
                          _activeTicket = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDish!.nameVi,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_lastMatchResult?.isCustomDetected == true)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.purple.shade200),
                                  ),
                                  child: const Text(
                                    '✨ AI Real-Time Decoded Dish (Outside Static Catalog)',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                                  ),
                                ),
                            ],
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

                    // Open Chef Ticket Buttons
                    if (_activeTicket != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.flagYellow,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.receipt_long, size: 18),
                              label: const Text('Bilingual Ticket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => ChefTicketDialog(ticket: _activeTicket!),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.fullscreen, size: 18),
                              label: const Text('Giant Card & Voice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                FullscreenChefTicketScreen.open(context, _activeTicket!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Assertive Tourist Advisory Box
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _verdict!.level == SafetyLevel.red
                            ? const Color(0xFFFEF2F2)
                            : _verdict!.level == SafetyLevel.yellow
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _verdict!.level == SafetyLevel.red
                              ? const Color(0xFFF87171)
                              : _verdict!.level == SafetyLevel.yellow
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF4ADE80),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _verdict!.level == SafetyLevel.red
                                    ? Icons.cancel
                                    : _verdict!.level == SafetyLevel.yellow
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle,
                                color: _verdict!.level == SafetyLevel.red
                                    ? AppColors.flagRed
                                    : _verdict!.level == SafetyLevel.yellow
                                        ? const Color(0xFFD97706)
                                        : AppColors.flagGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _verdict!.level == SafetyLevel.red
                                    ? 'CRITICAL TOURIST DIRECTIVE'
                                    : _verdict!.level == SafetyLevel.yellow
                                        ? 'ACTION REQUIRED BEFORE ORDERING'
                                        : '100% SAFE TO CONSUME',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: _verdict!.level == SafetyLevel.red
                                      ? AppColors.flagRed
                                      : _verdict!.level == SafetyLevel.yellow
                                          ? const Color(0xFFB45309)
                                          : AppColors.flagGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiActionAdvice ?? _verdict!.reason,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _verdict!.level == SafetyLevel.red
                                  ? const Color(0xFF991B1B)
                                  : _verdict!.level == SafetyLevel.yellow
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF166534),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // "What to Ask the Server" Card (Bilingual Phrase to Show Waiter)
                    if (_askWaiterVi != null && _askWaiterVi!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'WHAT TO ASK THE SERVER (SHOW TO STAFF):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                '"${_askWaiterVi!}"',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (_askWaiterEn != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Meaning for you: ${_askWaiterEn!}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
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
