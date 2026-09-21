"""Database access for user accounts."""

from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.conversation import Conversation
from app.models.diet_plan import DietPlan
from app.models.profile import Profile
from app.models.user import User
from app.models.weight_entry import WeightEntry


def get_by_email(db: Session, email: str) -> User | None:
    # Stored lowercase so Piash@x.com and piash@x.com are one account.
    return db.scalar(select(User).where(User.email == email.lower()))


def get_by_id(db: Session, user_id: int) -> User | None:
    return db.get(User, user_id)


def create(
    db: Session, *, email: str, name: str, password: str, role: str = "user"
) -> User:
    """Create an account. Role defaults to 'user' and is never taken from a request."""
    user = User(
        email=email.lower(),
        name=name,
        password_hash=hash_password(password),
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def set_password(db: Session, user: User, new_password: str) -> User:
    user.password_hash = hash_password(new_password)
    user.must_change_password = False
    db.commit()
    db.refresh(user)
    return user


def touch_login(db: Session, user: User) -> None:
    user.last_login_at = datetime.now(timezone.utc)
    db.commit()


def update_details(db: Session, user: User, changes: dict) -> User:
    """Apply name and email changes. Email is lowercased to match lookup."""
    if "name" in changes and changes["name"]:
        user.name = changes["name"]
    if "email" in changes and changes["email"]:
        user.email = changes["email"].lower()

    db.commit()
    db.refresh(user)
    return user


def deactivate(db: Session, user: User) -> None:
    """Pause the account. Data is untouched."""
    user.deactivated_at = datetime.now(timezone.utc)
    db.commit()


def reactivate(db: Session, user: User) -> None:
    user.deactivated_at = None
    db.commit()


def delete(db: Session, user: User) -> None:
    """Remove the account and everything it owns.

    Profiles, conversations, plans and weight entries all cascade from the
    foreign keys, so this one statement clears the lot.
    """
    db.delete(user)
    db.commit()


# ----------------------------------------------------------------- admin


def list_with_counts(db: Session, limit: int = 200) -> list[dict]:
    """Every account with a summary of its activity.

    Counts are computed in SQL rather than by loading the rows, so a user
    with three hundred messages costs the same to list as one with none.
    """
    rows = db.execute(
        select(
            User,
            select(func.count(Conversation.id))
            .where(Conversation.user_id == User.id)
            .scalar_subquery()
            .label("conversations"),
            select(func.count(DietPlan.id))
            .where(DietPlan.user_id == User.id)
            .scalar_subquery()
            .label("plans"),
            select(func.count(WeightEntry.id))
            .where(WeightEntry.user_id == User.id)
            .scalar_subquery()
            .label("weights"),
            select(Profile.goal)
            .where(Profile.user_id == User.id)
            .scalar_subquery()
            .label("goal"),
        )
        .order_by(User.created_at.desc())
        .limit(limit)
    ).all()

    return [
        {
            "user": row[0],
            "conversations": row[1] or 0,
            "plans": row[2] or 0,
            "weights": row[3] or 0,
            # Goal is the last thing onboarding sets, so its presence is a
            # reasonable proxy for a finished profile.
            "complete": row[4] is not None,
        }
        for row in rows
    ]


def set_active(db: Session, user: User, active: bool) -> User:
    """Enable or disable an account.

    Distinct from deactivate(), which the account holder controls: this
    cannot be cleared by signing in, which is what makes it enforceable.
    """
    user.is_active = active
    db.commit()
    db.refresh(user)
    return user


def force_password(db: Session, user: User, new_password: str) -> None:
    """Set a password and require it to be changed at next sign-in."""
    user.password_hash = hash_password(new_password)
    user.must_change_password = True
    db.commit()