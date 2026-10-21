class Dish {
  final int id;
  final String nameVi;
  final String hiddenIngredients;
  final bool containsPork;
  final bool containsPeanut;
  final bool isSafeForHalal;
  final bool requiresKitchenConfirmation;
  final String? category;
  final String? notes;

  const Dish({
    required this.id,
    required this.nameVi,
    required this.hiddenIngredients,
    this.containsPork = false,
    this.containsPeanut = false,
    this.isSafeForHalal = false,
    this.requiresKitchenConfirmation = false,
    this.category,
    this.notes,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nameVi: json['name_vi']?.toString() ?? '',
      hiddenIngredients: json['hidden_ingredients']?.toString() ?? '',
      containsPork: json['contains_pork'] == true,
      containsPeanut: json['contains_peanut'] == true,
      isSafeForHalal: json['is_safe_for_halal'] == true,
      requiresKitchenConfirmation:
          json['requires_kitchen_confirmation'] == true,
      category: json['category']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_vi': nameVi,
      'hidden_ingredients': hiddenIngredients,
      'contains_pork': containsPork,
      'contains_peanut': containsPeanut,
      'is_safe_for_halal': isSafeForHalal,
      'requires_kitchen_confirmation': requiresKitchenConfirmation,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
    };
  }
}
