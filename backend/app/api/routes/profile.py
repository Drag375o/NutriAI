"""Profile endpoints: read, update, and the health numbers derived from it."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.dependencies import current_user
from app.db.session import get_db
from app.models.profile import Profile
from app.models.user import User
from app.repositories import profile_repo
from app.schemas.profile import BMIRead, ProfileRead, ProfileUpdate
from app.services.health_calc import (
    calculate_bmi,
    calculate_bmr,
    calculate_daily_calories,
)

router = APIRouter(prefix="/profile", tags=["profile"])


def _to_read(profile: Profile) -> ProfileRead:
    """Attach the derived numbers to the stored ones."""
    data = ProfileRead.model_validate(profile)

    if profile.height_cm and profile.weight_kg:
        bmi = calculate_bmi(profile.weight_kg, profile.height_cm)
        data.bmi = BMIRead(value=bmi.value, category=bmi.category, note=bmi.note)

        if profile.age:
            bmr = calculate_bmr(
                profile.weight_kg, profile.height_cm, profile.age, profile.sex
            )
            data.daily_calories = calculate_daily_calories(
                bmr, profile.activity_level, profile.goal
            )

    data.is_complete = all(
        [profile.age, profile.height_cm, profile.weight_kg, profile.goal]
    )
    return data


@router.get("", response_model=ProfileRead)
def read_profile(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> ProfileRead:
    # The user id comes from the verified token, never from the request,
    # so there is no parameter to tamper with.
    return _to_read(profile_repo.get_or_create(db, user.id))


@router.patch("", response_model=ProfileRead)
def update_profile(
    changes: ProfileUpdate,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> ProfileRead:
    # exclude_unset keeps untouched fields untouched, rather than nulling them.
    updated = profile_repo.update(db, user.id, changes.model_dump(exclude_unset=True))
    return _to_read(updated)