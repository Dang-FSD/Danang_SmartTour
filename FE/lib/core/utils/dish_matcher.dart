import 'package:danang_smarttour/data/models/dish_model.dart';

class MatchResult {
  final Dish dish;
  final bool isExactMatch;
  final bool isCustomDetected;
  final double confidenceScore;
  final String matchedKeyword;

  const MatchResult({
    required this.dish,
    required this.isExactMatch,
    required this.isCustomDetected,
    required this.confidenceScore,
    required this.matchedKeyword,
  });
}

class DishMatcher {
  /// Known regional dishes sold widely across Da Nang with specific keywords
  static final Map<String, List<String>> _dishAliases = {
    // ─── Da Nang Local Specialties ──────────────────────────────────
    'mì quảng': [
      'mi quang',
      'quang noodles',
      'quang style noodle',
      'turmeric noodles',
      'mì quảng gà',
      'mi quang ga',
      'chicken quang noodles',
    ],
    'bún chả cá': [
      'bun cha ca',
      'fish cake noodle soup',
      'danang fish cake soup',
      'bun cha ca da nang',
      'fish cake soup',
    ],
    'bánh xèo': [
      'banh xeo',
      'crispy pancake',
      'vietnamese crepe',
      'sizzling pancake',
      'banh xeo chay',
      'banh xeo nam',
      'mushroom pancake',
    ],
    'ram bắp': [
      'ram bap',
      'corn spring roll',
      'crispy corn rolls',
      'fried corn roll',
      'ram bap da nang',
      'corn roll',
    ],
    'gỏi cá nam ô': [
      'goi ca nam o',
      'nam o raw fish salad',
      'raw fish salad',
      'herring salad',
    ],
    'bánh tráng cuốn thịt heo': [
      'banh trang cuon thit heo',
      'pork rice paper roll',
      'pork belly roll',
      'danang pork roll',
    ],
    'bún mắm nêm': [
      'bun mam nem',
      'fermented anchovy noodle',
      'anchovy sauce noodles',
      'pork fermented noodle',
    ],
    'bánh bèo': [
      'banh beo',
      'steamed rice cakes',
      'water fern cakes',
      'savory rice cake',
    ],

    // ─── Popular Regional Dishes Widely Sold in Da Nang ─────────────
    'bánh mì': [
      'banh mi',
      'banh mi thit',
      'banh mi da nang',
      'banh mi pate',
      'vietnamese sandwich',
      'vietnamese baguette',
      'bread stuffed',
      'banh mi cha bo',
      'banh mi que',
      'banh my',
    ],
    'bún chả hà nội': [
      'bun cha ha noi',
      'bun cha',
      'hanoi grilled pork',
      'grilled pork noodles',
      'hanoi bun cha',
      'thit nuong bun cha',
    ],
    'phở bò': [
      'pho bo',
      'beef pho',
      'hanoi beef pho',
      'vietnamese beef noodle soup',
      'pho bo tai',
      'pho tai nam',
    ],
    'bún bò huế': [
      'bun bo hue',
      'hue spicy beef noodle',
      'spicy beef noodle soup',
      'bun bo',
    ],
    'cơm tấm sài gòn': [
      'com tam',
      'com tam sai gon',
      'broken rice',
      'broken rice with pork chop',
      'com suon',
    ],
    'bún đậu mắm tôm': [
      'bun dau mam tom',
      'bun dau',
      'fried tofu with shrimp paste',
      'tofu vermicelli shrimp paste',
    ],
    'cao lầu': [
      'cao lau',
      'cao lau hoi an',
      'hoi an pork noodles',
    ],
  };

  /// Normalizes string: lowercase, trims, removes Vietnamese diacritics
  static String removeDiacritics(String str) {
    var withDia = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    var withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  /// Safely checks if input contains a keyword using strict word boundary logic
  static bool _matchesKeyword(String text, String keyword) {
    final cleanText = ' ' + removeDiacritics(text).replaceAll(RegExp(r'[^a-z0-9]'), ' ') + ' ';
    final cleanKeyword = ' ' + removeDiacritics(keyword).replaceAll(RegExp(r'[^a-z0-9]'), ' ') + ' ';
    return cleanText.contains(cleanKeyword);
  }

  /// Matches AI detected text or dish name against available catalog or dynamically constructs one
  static MatchResult matchOrConstructDish({
    required String detectedRawName,
    required List<Dish> availableDishes,
    Map<String, dynamic>? aiPayload,
    String? fileNameHint,
  }) {
    String cleanInput = removeDiacritics(detectedRawName).trim();

    // If input is empty, leverage file name or image metadata cues as local heuristic
    if (cleanInput.isEmpty && fileNameHint != null && fileNameHint.isNotEmpty) {
      cleanInput = removeDiacritics(fileNameHint).replaceAll(RegExp(r'[-_]'), ' ').trim();
    }

    // If still empty, return explicitly Unidentified Result (NEVER fake Bún chả cá)
    if (cleanInput.isEmpty) {
      return const MatchResult(
        dish: Dish(
          id: 0,
          nameVi: 'Món ăn chưa nhận diện được (Unidentified)',
          hiddenIngredients: 'Vui lòng chọn món ăn từ danh sách mẫu bên dưới hoặc chụp lại hình ảnh rõ nét hơn.',
          containsPork: false,
          containsPeanut: false,
          isSafeForHalal: true,
        ),
        isExactMatch: false,
        isCustomDetected: false,
        confidenceScore: 0.0,
        matchedKeyword: 'Unidentified Dish',
      );
    }

    // ─── STEP 0A: Check if Bánh Mì ──────────────────────────────────
    final isBanhMi = _matchesKeyword(cleanInput, 'banh mi') ||
        _matchesKeyword(cleanInput, 'banh my') ||
        _matchesKeyword(cleanInput, 'bread stuffed');

    if (isBanhMi) {
      final inCatalog = availableDishes.where(
        (d) => removeDiacritics(d.nameVi).contains('banh mi'),
      );
      if (inCatalog.isNotEmpty) {
        return MatchResult(
          dish: inCatalog.first,
          isExactMatch: false,
          isCustomDetected: false,
          confidenceScore: 0.92,
          matchedKeyword: 'Bánh Mì (Street Food Specialty)',
        );
      }
      return _constructDynamicRegionalDish('bánh mì', aiPayload);
    }

    // ─── STEP 0B: Check if Bún Chả Hà Nội ───────────────────────────
    final isBunChaHanoi = _matchesKeyword(cleanInput, 'bun cha ha noi') ||
        (_matchesKeyword(cleanInput, 'bun cha') && !_matchesKeyword(cleanInput, 'bun cha ca'));

    if (isBunChaHanoi) {
      final inCatalog = availableDishes.where(
        (d) => removeDiacritics(d.nameVi).contains('bun cha ha noi'),
      );
      if (inCatalog.isNotEmpty) {
        return MatchResult(
          dish: inCatalog.first,
          isExactMatch: true,
          isCustomDetected: false,
          confidenceScore: 0.95,
          matchedKeyword: 'Bún Chả Hà Nội (Northern Specialty)',
        );
      }
      return _constructDynamicRegionalDish('bún chả hà nội', aiPayload);
    }

    // ─── STEP 1: Check Exact Name Match in Local Catalog ────────────
    for (final dish in availableDishes) {
      final cleanDishName = removeDiacritics(dish.nameVi);
      if (cleanDishName == cleanInput || _matchesKeyword(cleanInput, cleanDishName)) {
        return MatchResult(
          dish: dish,
          isExactMatch: true,
          isCustomDetected: false,
          confidenceScore: 0.95,
          matchedKeyword: dish.nameVi,
        );
      }
    }

    // ─── STEP 2: Check Regional Multi-Cuisine Aliases ───────────────
    for (final entry in _dishAliases.entries) {
      final canonicalKey = entry.key;
      final aliases = entry.value;

      for (final alias in aliases) {
        if (_matchesKeyword(cleanInput, alias)) {
          // If canonicalKey is in local catalog, return it
          final inCatalog = availableDishes.where(
            (d) => removeDiacritics(d.nameVi).contains(removeDiacritics(canonicalKey)),
          );

          if (inCatalog.isNotEmpty) {
            return MatchResult(
              dish: inCatalog.first,
              isExactMatch: false,
              isCustomDetected: false,
              confidenceScore: 0.90,
              matchedKeyword: alias,
            );
          }

          // Otherwise, construct dynamic dish for regional item
          return _constructDynamicRegionalDish(canonicalKey, aiPayload);
        }
      }
    }

    // ─── STEP 3: Fallback to Dynamic AI Vision Synthesis ────────────
    if (aiPayload != null && aiPayload['dish_name'] != null) {
      final String dishName = aiPayload['dish_name'].toString();
      final String ingredients = aiPayload['hidden_ingredients']?.toString() ??
          (aiPayload['ingredients'] is List
              ? (aiPayload['ingredients'] as List).join(', ')
              : 'Decoded by AI Vision');

      final lowerIng = ingredients.toLowerCase();
      final containsPork = aiPayload['contains_pork'] == true ||
          lowerIng.contains('pork') ||
          lowerIng.contains('heo') ||
          lowerIng.contains('lợn') ||
          lowerIng.contains('lard') ||
          lowerIng.contains('mỡ') ||
          lowerIng.contains('chả nướng');

      final containsPeanut = aiPayload['contains_peanut'] == true ||
          lowerIng.contains('peanut') ||
          lowerIng.contains('đậu phộng') ||
          lowerIng.contains('lạc');

      final isSafeHalal = !containsPork && !lowerIng.contains('wine') && !lowerIng.contains('rượu');

      return MatchResult(
        dish: Dish(
          id: 9999, // Dynamic generated ID
          nameVi: dishName,
          hiddenIngredients: ingredients,
          containsPork: containsPork,
          containsPeanut: containsPeanut,
          isSafeForHalal: isSafeHalal,
          requiresKitchenConfirmation: aiPayload['requires_kitchen_confirmation'] == true,
        ),
        isExactMatch: false,
        isCustomDetected: true,
        confidenceScore: (aiPayload['confidence'] is num)
            ? (aiPayload['confidence'] as num).toDouble()
            : 0.85,
        matchedKeyword: 'AI Vision Dynamic Deconstruction',
      );
    }

    // ─── STEP 4: Safe Unidentified Match (NEVER fake Bún Chả Cá) ─────
    return const MatchResult(
      dish: Dish(
        id: 0,
        nameVi: 'Món ăn chưa nhận diện được (Unidentified)',
        hiddenIngredients: 'Vui lòng chọn món ăn từ danh sách mẫu bên dưới hoặc chụp lại hình ảnh rõ nét hơn.',
        containsPork: false,
        containsPeanut: false,
        isSafeForHalal: true,
      ),
      isExactMatch: false,
      isCustomDetected: false,
      confidenceScore: 0.0,
      matchedKeyword: 'Unidentified Dish',
    );
  }

  static MatchResult _constructDynamicRegionalDish(String key, Map<String, dynamic>? aiPayload) {
    if (key == 'bánh mì' || key == 'banh mi') {
      return const MatchResult(
        dish: Dish(
          id: 9005,
          nameVi: 'Bánh Mì Thịt Pate Đà Nẵng',
          hiddenIngredients: 'Bánh mì giòn, pate gan heo, chả lụa heo, thịt nguội, bơ trứng, sốt ớt chua ngọt',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
        ),
        isExactMatch: true,
        isCustomDetected: true,
        confidenceScore: 0.92,
        matchedKeyword: 'Bánh Mì Thịt Pate (Popular Street Food)',
      );
    } else if (key == 'bún chả hà nội') {
      return const MatchResult(
        dish: Dish(
          id: 9001,
          nameVi: 'Bún Chả Hà Nội',
          hiddenIngredients: 'Chả thịt băm nướng than hoa, thịt ba chỉ nướng, nước mắm pha dấm đường, mỡ lợn, tỏi ớt',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
          requiresKitchenConfirmation: false,
        ),
        isExactMatch: true,
        isCustomDetected: true,
        confidenceScore: 0.95,
        matchedKeyword: 'Bún Chả Hà Nội (Northern Specialty)',
      );
    }
    if (key == 'phở bò') {
      return const MatchResult(
        dish: Dish(
          id: 9002,
          nameVi: 'Phở Bò Hà Nội',
          hiddenIngredients: 'Nước dùng ninh xương bò, quế, hồi, gừng nướng, thịt bò tái/nạm',
          containsPork: false,
          containsPeanut: false,
          isSafeForHalal: true,
        ),
        isExactMatch: true,
        isCustomDetected: true,
        confidenceScore: 0.92,
        matchedKeyword: 'Phở Bò (Northern Specialty)',
      );
    } else if (key == 'cơm tấm sài gòn') {
      return const MatchResult(
        dish: Dish(
          id: 9003,
          nameVi: 'Cơm Tấm Sườn Nướng',
          hiddenIngredients: 'Sườn heo nướng than, mỡ hành, chả trứng heo, nước mắm tỏi ớt',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
        ),
        isExactMatch: true,
        isCustomDetected: true,
        confidenceScore: 0.92,
        matchedKeyword: 'Cơm Tấm (Southern Specialty)',
      );
    } else if (key == 'bún đậu mắm tôm') {
      return const MatchResult(
        dish: Dish(
          id: 9004,
          nameVi: 'Bún Đậu Mắm Tôm',
          hiddenIngredients: 'Đậu hũ rán, thịt chân giò luộc, chả cốm, mắm tôm lên men',
          containsPork: true,
          isSafeForHalal: false,
        ),
        isExactMatch: true,
        isCustomDetected: true,
        confidenceScore: 0.92,
        matchedKeyword: 'Bún Đậu Mắm Tôm',
      );
    }

    return MatchResult(
      dish: Dish(
        id: 9099,
        nameVi: key.toUpperCase(),
        hiddenIngredients: 'Regional dish sold in Da Nang',
      ),
      isExactMatch: false,
      isCustomDetected: true,
      confidenceScore: 0.85,
      matchedKeyword: key,
    );
  }
}
