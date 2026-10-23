import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';
import 'package:danang_smarttour/presentation/providers/app_providers.dart';

class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(travelerProfileProvider);
    final notifier = ref.read(travelerProfileProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Traveler Safety & Health Profile'),
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
            // Quick Test Presets (Ground-Truth Testing Bar)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.goldenSand, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Quick Test Profiles (Ground-Truth Cases)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip(
                        label: 'Ali (Halal)',
                        selected: profile.dietRule == 'halal',
                        onTap: () =>
                            notifier.switchPreset(TravelerProfile.sampleHalal),
                      ),
                      _buildPresetChip(
                        label: 'John (Cardiac Patient)',
                        selected: profile.medicalCondition == 'heart_disease',
                        onTap: () =>
                            notifier.switchPreset(TravelerProfile.sampleHeart),
                      ),
                      _buildPresetChip(
                        label: 'Emma (Peanut Allergy)',
                        selected: profile.allergen == 'peanut',
                        onTap: () =>
                            notifier.switchPreset(TravelerProfile.samplePeanut),
                      ),
                      _buildPresetChip(
                        label: 'Nam (Vegan & Fit)',
                        selected: profile.dietRule == 'vegan' &&
                            profile.fitnessLevel == 'high',
                        onTap: () => notifier
                            .switchPreset(TravelerProfile.sampleFitVegan),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Personal Info & Fitness
            _buildSectionCard(
              title: 'Personal Info & Fitness Level',
              icon: Icons.person,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: profile.displayName,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      notifier
                          .updateProfile(profile.copyWith(displayName: val));
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Physical Fitness Level:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'low', label: Text('Low / Cardiac')),
                      ButtonSegment(value: 'moderate', label: Text('Moderate')),
                      ButtonSegment(value: 'high', label: Text('High / Fit')),
                    ],
                    selected: {profile.fitnessLevel},
                    onSelectionChanged: (set) =>
                        notifier.setFitnessLevel(set.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dietary Rules & Faith
            _buildSectionCard(
              title: 'Dietary Restrictions & Faith',
              icon: Icons.restaurant,
              child: Column(
                children: [
                  RadioListTile<String?>(
                    title: const Text('Standard (No dietary restrictions)'),
                    value: null,
                    groupValue: profile.dietRule,
                    onChanged: notifier.setDietRule,
                  ),
                  RadioListTile<String?>(
                    title: const Text('Halal (Islamic Dietary Laws)'),
                    subtitle:
                        const Text('No pork, lard, or bone-stewed broths'),
                    value: 'halal',
                    groupValue: profile.dietRule,
                    onChanged: notifier.setDietRule,
                  ),
                  RadioListTile<String?>(
                    title: const Text('Strict Vegan (Plant-based)'),
                    subtitle: const Text(
                        'No meat, seafood, or fermented fish sauces'),
                    value: 'vegan',
                    groupValue: profile.dietRule,
                    onChanged: notifier.setDietRule,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Allergies
            _buildSectionCard(
              title: 'Food Allergies (Critical Safety)',
              icon: Icons.medical_services_outlined,
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Peanut / Groundnut Allergy'),
                    subtitle: const Text(
                        'High risk in Mi Quang broth, peanut oil, and crushed peanut garnish'),
                    value: profile.allergen == 'peanut',
                    onChanged: (checked) {
                      if (checked == true) {
                        notifier.setAllergen('peanut');
                      } else {
                        notifier.clearAllergies();
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Seafood & Shellfish Allergy'),
                    subtitle: const Text(
                        'High risk in shrimp paste, fish sauce, and Central Vietnamese broths'),
                    value: profile.allergen == 'seafood',
                    onChanged: (checked) {
                      if (checked == true) {
                        notifier.setAllergen('seafood');
                      } else {
                        notifier.clearAllergies();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cardiac Conditions
            _buildSectionCard(
              title: 'Medical & Cardiac History',
              icon: Icons.favorite,
              child: SwitchListTile(
                title: const Text('Cardiac Disease / Hypertension History'),
                subtitle: const Text(
                    'Triggers warnings for steep cliffside trekking (Mui Nghe, Ban Co Peak)'),
                value: profile.medicalCondition == 'heart_disease',
                onChanged: (active) {
                  notifier.setMedicalCondition(active ? 'heart_disease' : null);
                  if (active) notifier.setFitnessLevel('low');
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      backgroundColor: selected ? AppColors.primaryBlue : AppColors.background,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
