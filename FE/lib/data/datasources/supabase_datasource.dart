import 'package:flutter/foundation.dart';
import 'package:danang_smarttour/core/config/supabase_config.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';
import 'package:danang_smarttour/data/models/itinerary_model.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';

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
      final profileMap = profile.toProfileMap();
      final targetUserId = profileMap['id'];

      // 1. Upsert profiles
      await SupabaseConfig.client!.from('profiles').upsert(profileMap);

      // 2. Handle health_profiles (check if user already has an entry)
      final healthData = profile.toHealthProfileMap();
      final existing = await SupabaseConfig.client!
          .from('health_profiles')
          .select('id')
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (existing != null) {
        await SupabaseConfig.client!
            .from('health_profiles')
            .update(healthData)
            .eq('id', existing['id']);
      } else {
        await SupabaseConfig.client!
            .from('health_profiles')
            .insert(healthData);
      }

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

  /// Lưu bản ghi lịch trình vào bảng 'itineraries' và 'itinerary_stops'
  static Future<Itinerary?> saveItinerary(Itinerary itinerary) async {
    if (!isAvailable) return itinerary;
    try {
      // 1. Ghi vào bảng itineraries
      final insertedItinerary = await SupabaseConfig.client!
          .from('itineraries')
          .insert({
            'user_id': itinerary.userId,
            'title': itinerary.title,
            'status': 'draft',
          })
          .select()
          .single();

      final int itineraryId = insertedItinerary['id'] is int
          ? insertedItinerary['id']
          : int.parse(insertedItinerary['id'].toString());

      // 2. Ghi các điểm dừng vào itinerary_stops
      if (itinerary.stops.isNotEmpty) {
        final stopsData = itinerary.stops.map((stop) {
          return {
            'itinerary_id': itineraryId,
            'safety_level': stop.safetyLevel == SafetyLevel.red
                ? 'RED'
                : (stop.safetyLevel == SafetyLevel.yellow ? 'YELLOW' : 'GREEN'),
            'safety_reason': stop.safetyReason,
          };
        }).toList();

        await SupabaseConfig.client!.from('itinerary_stops').insert(stopsData);
      }

      // 3. BƯỚC BẮT BUỘC: verify_itinerary_status (Kiểm tra tính toàn vẹn)
      final bool verified = await verifyItineraryStatus(itineraryId);
      if (verified) {
        await SupabaseConfig.client!
            .from('itineraries')
            .update({'status': 'verified'})
            .eq('id', itineraryId);

        // Ghi log Agent thành công
        try {
          await SupabaseConfig.client!.from('agent_logs').insert({
            'tool_name': 'save_itinerary_ticket',
            'action_type': 'save_itinerary',
            'success': true,
            'user_id': itinerary.userId.length == 36 ? itinerary.userId : null,
          });
        } catch (_) {}

        return Itinerary(
          id: itineraryId,
          userId: itinerary.userId,
          title: itinerary.title,
          objective: itinerary.objective,
          duration: itinerary.duration,
          status: 'verified',
          summary: itinerary.summary,
          stops: itinerary.stops.map((s) => ItineraryStop(
            id: s.id,
            itineraryId: itineraryId,
            timeSlot: s.timeSlot,
            name: s.name,
            category: s.category,
            safetyLevel: s.safetyLevel,
            safetyReason: s.safetyReason,
            isRerouted: s.isRerouted,
            originalName: s.originalName,
            latitude: s.latitude,
            longitude: s.longitude,
            chefTicketWarning: s.chefTicketWarning,
          )).toList(),
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Verification failed for itinerary ID $itineraryId');
      }
    } catch (e) {
      debugPrint('[Supabase] saveItinerary error: $e');
      try {
        await SupabaseConfig.client!.from('agent_logs').insert({
          'tool_name': 'save_itinerary_ticket',
          'action_type': 'save_itinerary',
          'success': false,
          'error_msg': 'Rollback on write error: $e',
        });
      } catch (_) {}
      return itinerary; // Fallback to memory
    }
  }

  /// Xác minh tính toàn vẹn của lịch trình trong Database
  static Future<bool> verifyItineraryStatus(int itineraryId) async {
    if (!isAvailable) return true;
    try {
      final res = await SupabaseConfig.client!
          .from('itineraries')
          .select('id, title, status')
          .eq('id', itineraryId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      debugPrint('[Supabase] verifyItineraryStatus error: $e');
      return false;
    }
  }

  /// Lấy danh sách lịch trình đã lưu của du khách
  static Future<List<Itinerary>> fetchUserItineraries(String userId) async {
    if (!isAvailable) return [];
    try {
      final res = await SupabaseConfig.client!
          .from('itineraries')
          .select()
          .eq('user_id', userId)
          .order('id', ascending: false);

      final List<dynamic> list = res;
      return list.map((item) => Itinerary.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Supabase] fetchUserItineraries error: $e');
      return [];
    }
  }
}
