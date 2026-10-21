import 'package:flutter/foundation.dart';
import 'package:danang_smarttour/core/config/supabase_config.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';

class SupabaseDataSource {
  static bool get isAvailable => SupabaseConfig.isInitialized;

  /// Đọc danh sách món ăn từ bảng 'dishes'
  static Future<List<Dish>?> fetchDishes() async {
    if (!isAvailable) return null;
    try {
      final response = await SupabaseConfig.client!
          .from('dishes')
          .select()
          .order('id', ascending: true);
      final List<dynamic> data = response;
      return data.map((e) => Dish.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[Supabase] fetchDishes error: $e');
      return null;
    }
  }

  /// Đọc danh sách điểm đến từ bảng 'attractions'
  static Future<List<Attraction>?> fetchAttractions() async {
    if (!isAvailable) return null;
    try {
      final response = await SupabaseConfig.client!
          .from('attractions')
          .select()
          .order('id', ascending: true);
      final List<dynamic> data = response;
      return data.map((e) => Attraction.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[Supabase] fetchAttractions error: $e');
      return null;
    }
  }

  /// Lưu hoặc cập nhật hồ sơ du khách vào 'profiles' và 'health_profiles'
  static Future<bool> upsertProfile(TravelerProfile profile) async {
    if (!isAvailable) return false;
    try {
      // 1. Upsert profiles
      await SupabaseConfig.client!.from('profiles').upsert(profile.toProfileMap());

      // 2. Upsert health_profiles
      await SupabaseConfig.client!
          .from('health_profiles')
          .upsert(profile.toHealthProfileMap());

      return true;
    } catch (e) {
      debugPrint('[Supabase] upsertProfile error: $e');
      return false;
    }
  }

  /// Lưu thẻ cảnh báo an toàn và gọi xác minh (Verification Gatekeeper)
  static Future<SafetyTicket?> saveAndVerifyTicket(SafetyTicket ticket) async {
    if (!isAvailable) return null;
    try {
      // 1. Lưu vé vào Supabase
      final inserted = await SupabaseConfig.client!
          .from('safety_tickets')
          .insert(ticket.toJson())
          .select()
          .single();

      final ticketId = inserted['id'];

      // 2. BƯỚC BẮT BUỘC: verify_itinerary_status (đọc ngược lại DB để kiểm tra toàn vẹn)
      final verifyCheck = await SupabaseConfig.client!
          .from('safety_tickets')
          .select('id, ticket_code, bilingual_warning, verified')
          .eq('id', ticketId)
          .single();

      if (verifyCheck['ticket_code'] == ticket.ticketCode) {
        // Cập nhật verified = true
        await SupabaseConfig.client!
            .from('safety_tickets')
            .update({'verified': true})
            .eq('id', ticketId);

        // Ghi agent_logs thành công
        await SupabaseConfig.client!.from('agent_logs').insert({
          'action_type': 'save_ticket',
          'success': true,
          'user_id': ticket.userId.length == 36 ? ticket.userId : null,
        });

        return ticket.copyWith(
          id: ticketId is int ? ticketId : int.tryParse(ticketId.toString()),
          verified: true,
        );
      } else {
        throw Exception('Verification mismatch: Ticket code did not persist correctly.');
      }
    } catch (e) {
      debugPrint('[Supabase] saveAndVerifyTicket failed: $e');
      // Ghi log thất bại (CA 6 - Rollback notice)
      try {
        await SupabaseConfig.client!.from('agent_logs').insert({
          'action_type': 'save_ticket',
          'success': false,
          'error_msg': 'Network/DB Error - Rollback: $e',
        });
      } catch (_) {}
      return null;
    }
  }
}
