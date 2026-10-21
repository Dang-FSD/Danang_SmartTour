import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';

class LocalDataSource {
  static List<Dish> _cachedDishes = [];
  static List<Attraction> _cachedAttractions = [];
  static final List<SafetyTicket> _savedTickets = [];
  static TravelerProfile _currentProfile = TravelerProfile.samplePeanut;

  static TravelerProfile get currentProfile => _currentProfile;

  static void setProfile(TravelerProfile profile) {
    _currentProfile = profile;
  }

  /// Tải danh sách món ăn từ assets/data/dishes_seed.json
  static Future<List<Dish>> getDishes() async {
    if (_cachedDishes.isNotEmpty) return _cachedDishes;

    try {
      final jsonStr = await rootBundle.loadString('assets/data/dishes_seed.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      _cachedDishes = list.map((e) => Dish.fromJson(e)).toList();
      return _cachedDishes;
    } catch (e) {
      // Fallback default list
      return [
        const Dish(
          id: 1,
          nameVi: 'Bún chả cá Đà Nẵng',
          hiddenIngredients: 'Nước dùng ninh xương heo, chả cá, mắm ruốc',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
        ),
        const Dish(
          id: 2,
          nameVi: 'Mì Quảng Gà',
          hiddenIngredients: 'Nước lèo gà, phi dầu phộng, rắc đậu phộng rang',
          containsPork: false,
          containsPeanut: true,
          isSafeForHalal: true,
        ),
        const Dish(
          id: 3,
          nameVi: 'Bánh xèo nấm chay',
          hiddenIngredients: 'Nấm, bột gạo, dầu thực vật',
          containsPork: false,
          containsPeanut: false,
          isSafeForHalal: true,
        ),
        const Dish(
          id: 4,
          nameVi: 'Ram bắp gia truyền',
          hiddenIngredients: 'Nguyên liệu cuốn hỗn hợp mơ hồ, có thể chiên chung dầu lợn',
          requiresKitchenConfirmation: true,
        ),
      ];
    }
  }

  /// Tải danh sách điểm tham quan từ assets/data/attractions_seed.json
  static Future<List<Attraction>> getAttractions() async {
    if (_cachedAttractions.isNotEmpty) return _cachedAttractions;

    try {
      final jsonStr = await rootBundle.loadString('assets/data/attractions_seed.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      _cachedAttractions = list.map((e) => Attraction.fromJson(e)).toList();
      return _cachedAttractions;
    } catch (e) {
      return [
        const Attraction(
          id: 1,
          nameVi: 'Trekking Mũi Nghê',
          category: 'sport',
          difficulty: 'hard',
          isOverloaded: false,
          latitude: 16.1150,
          longitude: 108.3180,
          alternativeId: 20,
        ),
        const Attraction(
          id: 2,
          nameVi: 'Cầu Rồng (Giờ phun lửa)',
          category: 'culture',
          difficulty: 'easy',
          isOverloaded: true,
          latitude: 16.0610,
          longitude: 108.2272,
          alternativeId: 3,
        ),
        const Attraction(
          id: 3,
          nameVi: 'Làng đá Mỹ nghệ Non Nước',
          category: 'culture',
          difficulty: 'easy',
          isOverloaded: false,
          latitude: 16.0028,
          longitude: 108.2639,
        ),
        const Attraction(
          id: 4,
          nameVi: 'Chèo SUP Biển Mỹ Khê',
          category: 'sport',
          difficulty: 'moderate',
          isOverloaded: false,
          latitude: 16.0602,
          longitude: 108.2462,
        ),
      ];
    }
  }

  /// Lưu thẻ cảnh báo đầu bếp
  static Future<SafetyTicket> saveTicket(SafetyTicket ticket) async {
    final verifiedTicket = ticket.copyWith(
      id: _savedTickets.length + 1,
      verified: true, // Xác minh thành công
    );
    _savedTickets.add(verifiedTicket);
    return verifiedTicket;
  }

  /// Đọc danh sách vé đã lưu
  static List<SafetyTicket> getSavedTickets() => List.unmodifiable(_savedTickets);
}
