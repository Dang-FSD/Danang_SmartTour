import 'package:danang_smarttour/data/datasources/local_datasource.dart';
import 'package:danang_smarttour/data/datasources/supabase_datasource.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';
import 'package:danang_smarttour/data/models/itinerary_model.dart';

class SmartTourRepository {
  /// Lấy danh sách món ăn Đà Nẵng (Ưu tiên Supabase, fallback Local)
  Future<List<Dish>> getDishes() async {
    final remote = await SupabaseDataSource.fetchDishes();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }
    return LocalDataSource.getDishes();
  }

  /// Lấy danh sách điểm tham quan (Ưu tiên Supabase, fallback Local)
  Future<List<Attraction>> getAttractions() async {
    final remote = await SupabaseDataSource.fetchAttractions();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }
    return LocalDataSource.getAttractions();
  }

  /// Lưu hồ sơ du khách
  Future<void> saveProfile(TravelerProfile profile) async {
    LocalDataSource.setProfile(profile);
    await SupabaseDataSource.upsertProfile(profile);
  }

  /// Đọc hồ sơ du khách hiện tại
  TravelerProfile getCurrentProfile() {
    return LocalDataSource.currentProfile;
  }

  /// Lưu và xác minh thẻ cảnh báo an toàn (Đảm bảo Zero False-Safety)
  Future<SafetyTicket> saveAndVerifyTicket(SafetyTicket ticket) async {
    // Thử lưu Supabase trước
    final remoteResult = await SupabaseDataSource.saveAndVerifyTicket(ticket);
    if (remoteResult != null) {
      return remoteResult;
    }
    // Fallback lưu local
    return LocalDataSource.saveTicket(ticket);
  }

  /// Đọc danh sách vé an toàn
  List<SafetyTicket> getSavedTickets() {
    return LocalDataSource.getSavedTickets();
  }

  /// Lưu và xác minh lịch trình thích ứng (Agentic Itinerary)
  Future<Itinerary> saveItinerary(Itinerary itinerary) async {
    final remote = await SupabaseDataSource.saveItinerary(itinerary);
    return remote ?? itinerary;
  }

  /// Lấy danh sách lịch trình đã lưu
  Future<List<Itinerary>> getSavedItineraries(String userId) async {
    return SupabaseDataSource.fetchUserItineraries(userId);
  }
}
