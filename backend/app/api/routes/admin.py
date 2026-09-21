"""Administration endpoints.

Every route here depends on current_admin, which reads the role from the
database rather than the token, so revoking admin takes effect at once.
"""

import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import current_admin
from app.db.session import get_db
from app.models.user import User
from app.repositories import user_repo
from app.schemas.admin import (
    AdminStats,
    AdminUserRow,
    AdminUserUpdate,
    TemporaryPassword,
)

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/stats", response_model=AdminStats)
def stats(
    admin: User = Depends(current_admin), db: Session = Depends(get_db)
) -> AdminStats:
    rows = user_repo.list_with_counts(db, limit=10_000)
    users = [r["user"] for r in rows]

    week_ago = datetime.now(timezone.utc) - timedelta(days=7)

    return AdminStats(
        total_users=len(users),
        active_users=sum(
            1 for u in users if u.is_active and u.deactivated_at is None
        ),
        deactivated_users=sum(1 for u in users if u.deactivated_at is not None),
        disabled_users=sum(1 for u in users if not u.is_active),
        admins=sum(1 for u in users if u.role == "admin"),
        signed_in_this_week=sum(
            1
            for u in users
            if u.last_login_at is not None
            and u.last_login_at.replace(tzinfo=timezone.utc) >= week_ago
        ),
    )


@router.get("/users", response_model=list[AdminUserRow])
def list_users(
    admin: User = Depends(current_admin), db: Session = Depends(get_db)
) -> list[AdminUserRow]:
    rows = user_repo.list_with_counts(db)

    return [
        AdminUserRow(
            **AdminUserRow.model_validate(r["user"]).model_dump(
                exclude={
                    "conversation_count",
                    "plan_count",
                    "weight_entry_count",
                    "profile_complete",
                }
            ),
            conversation_count=r["conversations"],
            plan_count=r["plans"],
            weight_entry_count=r["weights"],
            profile_complete=r["complete"],
        )
        for r in rows
    ]


@router.patch("/users/{user_id}", response_model=AdminUserRow)
def update_user(
    user_id: int,
    payload: AdminUserUpdate,
    admin: User = Depends(current_admin),
    db: Session = Depends(get_db),
) -> AdminUserRow:
    """Enable or disable an account.

    Disabling is distinct from the user's own deactivation: it cannot be
    cleared by signing in, which is what makes it enforceable.
    """
    target = user_repo.get_by_id(db, user_id)
    if target is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That account does not exist.",
        )

    # Locking yourself out is not a recoverable mistake through this API.
    if target.id == admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot disable your own account here.",
        )

    if payload.is_active is not None:
        user_repo.set_active(db, target, payload.is_active)

    return AdminUserRow.model_validate(target)


@router.post("/users/{user_id}/reset-password", response_model=TemporaryPassword)
def reset_password(
    user_id: int,
    admin: User = Depends(current_admin),
    db: Session = Depends(get_db),
) -> TemporaryPassword:
    """Issue a temporary password.

    The administrator sees a password they have just created, never the
    user's own, which remains a one-way hash. The user is required to
    change it at next sign-in.
    """
    target = user_repo.get_by_id(db, user_id)
    if target is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That account does not exist.",
        )

    # Long enough to resist guessing in the window before it is changed.
    temporary = secrets.token_urlsafe(9)
    user_repo.force_password(db, target, temporary)

    return TemporaryPassword(temporary_password=temporary)


@router.delete("/users/{user_id}", status_code=204)
def delete_user(
    user_id: int,
    admin: User = Depends(current_admin),
    db: Session = Depends(get_db),
) -> None:
    target = user_repo.get_by_id(db, user_id)
    if target is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That account does not exist.",
        )

    if target.id == admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Delete your own account from your profile instead.",
        )

    user_repo.delete(db, target)