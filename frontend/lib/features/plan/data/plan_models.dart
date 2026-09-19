/// One meal in a day's plan.
class Meal {
  const Meal({
    required this.id,
    required this.slot,
    required this.name,
    required this.calories,
    this.timeHint,
    this.portion,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.substitution,
  });

  final int id;

  /// 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final String slot;

  final String name;
  final int calories;

  /// Free text like "8:00 AM" or "Around midday". Displayed, not parsed.
  final String? timeHint;

  final String? portion;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  /// A one-line alternative the user can swap to.
  final String? substitution;

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as int,
        slot: json['slot'] as String,
        name: json['name'] as String,
        calories: json['calories'] as int? ?? 0,
        timeHint: json['time_hint'] as String?,
        portion: json['portion'] as String?,
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        substitution: json['substitution'] as String?,
      );
}

/// A day's plan.
class DietPlan {
  const DietPlan({
    required this.id,
    required this.planDate,
    required this.targetCalories,
    required this.totalCalories,
    required this.totalProteinG,
    required this.meals,
    this.goal,
    this.rationale,
  });

  final int id;
  final DateTime planDate;

  /// What the plan was built against, snapshotted at generation time.
  final int targetCalories;

  final int totalCalories;
  final double totalProteinG;
  final List<Meal> meals;
  final String? goal;

  /// The model's brief explanation. May be absent.
  final String? rationale;

  /// How far the plan lands from its target. Negative is under.
  int get calorieDelta => totalCalories - targetCalories;

  factory DietPlan.fromJson(Map<String, dynamic> json) => DietPlan(
        id: json['id'] as int,
        planDate: DateTime.parse(json['plan_date'] as String),
        targetCalories: json['target_calories'] as int? ?? 0,
        totalCalories: json['total_calories'] as int? ?? 0,
        totalProteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0,
        goal: json['goal'] as String?,
        rationale: json['rationale'] as String?,
        meals: (json['meals'] as List<dynamic>? ?? [])
            .map((m) => Meal.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

/// Ordering and labels for the meal slots. Kept here so the screen never
/// has to decide what "slot" strings mean.
abstract final class MealSlots {
  static const labels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };

  static String label(String slot) => labels[slot] ?? slot;
}