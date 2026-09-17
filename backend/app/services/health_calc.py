"""Health calculations: BMI, BMR, daily energy needs."""

from dataclasses import dataclass

# Mifflin-St Jeor activity multipliers.
ACTIVITY_FACTORS = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
}

# WHO adult BMI categories.
BMI_BANDS = [
    (18.5, "underweight"),
    (25.0, "healthy"),
    (30.0, "overweight"),
    (float("inf"), "obese"),
]

BMI_NOTES = {
    "underweight": "Below the typical range. Worth discussing with a doctor.",
    "healthy": "Within the typical range for adults.",
    "overweight": "Above the typical range.",
    "obese": "Well above the typical range. A doctor can give you a fuller picture.",
}

# No goal may push someone below this. Aggressive restriction is unsafe and
# NutriAI must not facilitate it (master prompt section 44).
MINIMUM_DAILY_CALORIES = 1200


@dataclass(frozen=True)
class BMIResult:
    value: float
    category: str
    note: str


def calculate_bmi(weight_kg: float, height_cm: float) -> BMIResult:
    """BMI as weight in kilograms over height in metres squared.

    BMI is one crude signal, not a verdict on anyone's health. It ignores
    muscle mass, body composition, age and ethnicity, so the wording stays
    descriptive rather than diagnostic.
    """
    if height_cm <= 0:
        raise ValueError("height_cm must be greater than zero")
    if weight_kg <= 0:
        raise ValueError("weight_kg must be greater than zero")

    height_m = height_cm / 100
    value = round(weight_kg / (height_m**2), 1)

    category = next(name for limit, name in BMI_BANDS if value < limit)
    return BMIResult(value=value, category=category, note=BMI_NOTES[category])


def calculate_bmr(
    weight_kg: float, height_cm: float, age: int, sex: str | None
) -> float:
    """Basal metabolic rate, Mifflin-St Jeor.

    The sex-specific constants come from the original study. Where sex is
    unknown or 'other', the midpoint is used rather than guessing.
    """
    base = (10 * weight_kg) + (6.25 * height_cm) - (5 * age)

    if sex == "male":
        return round(base + 5, 1)
    if sex == "female":
        return round(base - 161, 1)
    return round(base - 78, 1)


def calculate_daily_calories(
    bmr: float, activity_level: str | None, goal: str | None
) -> int:
    """Maintenance calories, adjusted for the user's goal.

    The deficit and surplus are deliberately modest: 500 kcal is roughly
    half a kilogram a week, which is a rate most guidance considers safe.
    """
    factor = ACTIVITY_FACTORS.get(activity_level or "", 1.2)
    maintenance = bmr * factor

    if goal == "lose":
        target = maintenance - 500
    elif goal == "gain":
        target = maintenance + 400
    else:
        target = maintenance

    return max(MINIMUM_DAILY_CALORIES, int(round(target)))