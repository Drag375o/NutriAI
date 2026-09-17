"""Database access for profiles. Every function is scoped to one user."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.profile import Profile


def get_or_create(db: Session, user_id: int) -> Profile:
    """That user's profile, created empty on first access."""
    profile = db.scalar(select(Profile).where(Profile.user_id == user_id))
    if profile is None:
        profile = Profile(user_id=user_id)
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


def update(db: Session, user_id: int, changes: dict) -> Profile:
    """Apply only the fields actually supplied.

    Fields absent from the request are left untouched, so a partial save
    from one onboarding step cannot wipe data entered in another.
    """
    profile = get_or_create(db, user_id)
    for field, value in changes.items():
        setattr(profile, field, value)
    db.commit()
    db.refresh(profile)
    return profile