"""Database access for user accounts."""

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.user import User


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


def list_all(db: Session, limit: int = 100, offset: int = 0) -> list[User]:
    """For the admin panel."""
    return list(
        db.scalars(select(User).order_by(User.created_at.desc()).limit(limit).offset(offset))
    )


def count(db: Session) -> int:
    return len(list(db.scalars(select(User.id))))