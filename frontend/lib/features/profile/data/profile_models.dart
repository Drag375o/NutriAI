/// BMI with its category and a plain-language note.
///
/// The interpretation comes from the server so the wording stays in one
/// place — this is health information, and it should not drift between
/// the API and the UI.
class BmiReading {
  const BmiReading({
    required this.value,
    required this.category,
    required this.note,
  });

  final double value;

  /// 'underweight' | 'healthy' | 'overweight' | 'obese'
  final String category;

  final String note;

  factory BmiReading.fromJson(Map<String, dynamic> json) => BmiReading(
        value: (json['value'] as num).toDouble(),
        category: json['category'] as String,
        note: json['note'] as String,
      );
}

/// A user's health profile. Every field is nullable: onboarding saves one
/// step at a time, and the AI asks for what is missing rather than guessing.
class Profile {
  const Profile({
    required this.id,
    required this.userId,
    this.age,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.goal,
    this.targetWeightKg,
    this.dietPreference,
    this.allergies,
    this.restrictions,
    this.conditions,
    this.bmi,
    this.dailyCalories,
    this.isComplete = false,
  });

  final int id;
  final int userId;

  final int? age;
  final String? sex;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? goal;
  final double? targetWeightKg;
  final String? dietPreference;
  final String? allergies;
  final String? restrictions;
  final String? conditions;

  /// Computed by the server, null until height and weight both exist.
  final BmiReading? bmi;
  final int? dailyCalories;

  /// True when there is enough here to personalise advice.
  final bool isComplete;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        age: json['age'] as int?,
        sex: json['sex'] as String?,
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        activityLevel: json['activity_level'] as String?,
        goal: json['goal'] as String?,
        targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
        dietPreference: json['diet_preference'] as String?,
        allergies: json['allergies'] as String?,
        restrictions: json['restrictions'] as String?,
        conditions: json['conditions'] as String?,
        bmi: json['bmi'] == null
            ? null
            : BmiReading.fromJson(json['bmi'] as Map<String, dynamic>),
        dailyCalories: json['daily_calories'] as int?,
        isComplete: json['is_complete'] as bool? ?? false,
      );
}

/// The options the backend accepts, with labels for display.
///
/// Kept here so the picker and the API can never disagree about the
/// values being sent.
abstract final class ProfileOptions {
  static const sexes = {
    'male': 'Male',
    'female': 'Female',
    'other': 'Other',
  };

  static const activityLevels = {
    'sedentary': 'Mostly sitting',
    'light': 'Lightly active',
    'moderate': 'Moderately active',
    'active': 'Very active',
    'very_active': 'Extremely active',
  };

  static const activityHints = {
    'sedentary': 'Desk work, little exercise',
    'light': 'Light exercise 1–3 days a week',
    'moderate': 'Exercise 3–5 days a week',
    'active': 'Hard exercise 6–7 days a week',
    'very_active': 'Physical job or twice-daily training',
  };

  static const goals = {
    'lose': 'Lose weight',
    'maintain': 'Stay where I am',
    'gain': 'Gain weight',
  };

  static const dietPreferences = {
    'none': 'No restrictions',
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'halal': 'Halal',
    'pescatarian': 'Pescatarian',
  };
}