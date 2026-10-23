import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:danang_smarttour/core/network/voke_client.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';
import 'package:danang_smarttour/data/models/itinerary_model.dart';
import 'package:danang_smarttour/data/repositories/smart_tour_repository.dart';

// Repository Provider
final smartTourRepositoryProvider = Provider<SmartTourRepository>((ref) {
  return SmartTourRepository();
});

// VokeAPI Client Provider
final vokeClientProvider = Provider<VokeClient>((ref) {
  return VokeClient();
});

// Traveler Profile Notifier & Provider
class TravelerProfileNotifier extends StateNotifier<TravelerProfile> {
  final SmartTourRepository _repository;

  TravelerProfileNotifier(this._repository)
      : super(_repository.getCurrentProfile());

  void updateProfile(TravelerProfile newProfile) {
    state = newProfile;
    _repository.saveProfile(newProfile);
  }

  void switchPreset(TravelerProfile preset) {
    updateProfile(preset);
  }

  void setDietRule(String? rule) {
    updateProfile(state.copyWith(dietRule: rule));
  }

  void setAllergen(String? allergen, {String severity = 'severe'}) {
    updateProfile(state.copyWith(
      allergen: allergen,
      allergenSeverity: severity,
    ));
  }

  void clearAllergies() {
    updateProfile(state.copyWith(allergen: null, allergenSeverity: null));
  }

  void setMedicalCondition(String? condition) {
    updateProfile(state.copyWith(medicalCondition: condition));
  }

  void setFitnessLevel(String level) {
    updateProfile(state.copyWith(fitnessLevel: level));
  }
}

final travelerProfileProvider =
    StateNotifierProvider<TravelerProfileNotifier, TravelerProfile>((ref) {
  final repo = ref.watch(smartTourRepositoryProvider);
  return TravelerProfileNotifier(repo);
});

// Dishes Provider
final dishesProvider = FutureProvider<List<Dish>>((ref) async {
  final repo = ref.watch(smartTourRepositoryProvider);
  return repo.getDishes();
});

// Attractions Provider
final attractionsProvider = FutureProvider<List<Attraction>>((ref) async {
  final repo = ref.watch(smartTourRepositoryProvider);
  return repo.getAttractions();
});

// Saved Safety Tickets Notifier & Provider
class SavedTicketsNotifier extends StateNotifier<List<SafetyTicket>> {
  final SmartTourRepository _repository;

  SavedTicketsNotifier(this._repository)
      : super(_repository.getSavedTickets());

  Future<SafetyTicket> saveAndVerify(SafetyTicket ticket) async {
    final verified = await _repository.saveAndVerifyTicket(ticket);
    state = [...state, verified];
    return verified;
  }
}

final savedTicketsProvider =
    StateNotifierProvider<SavedTicketsNotifier, List<SafetyTicket>>((ref) {
  final repo = ref.watch(smartTourRepositoryProvider);
  return SavedTicketsNotifier(repo);
});

// Active / Generated Itinerary Provider
final activeItineraryProvider = StateProvider<Itinerary?>((ref) => null);

// Saved Itineraries Provider
final savedItinerariesProvider = FutureProvider<List<Itinerary>>((ref) async {
  final repo = ref.watch(smartTourRepositoryProvider);
  final profile = ref.watch(travelerProfileProvider);
  return repo.getSavedItineraries(profile.id);
});
