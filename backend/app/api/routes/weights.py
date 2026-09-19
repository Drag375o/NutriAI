"""Weight tracking endpoints."""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories import weight_repo
from app.schemas.weight_entry import (
    WeightEntryCreate,
    WeightEntryRead,
    WeightHistory,
)

router = APIRouter(prefix="/weights", tags=["weight"])


@router.get("", response_model=WeightHistory)
def history(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> WeightHistory:
    """The full history plus a summary.

    Both in one response because the Progress screen needs both and two
    round trips would show the chart before the numbers above it.
    """
    # Seeds one entry from the profile for accounts created before weight
    # tracking existed. No-op once any entry exists.
    weight_repo.backfill_from_profile(db, user.id)

    entries = weight_repo.list_for_user(db, user.id)
    return WeightHistory(
        entries=[WeightEntryRead.model_validate(e) for e in entries],
        trend=weight_repo.trend(db, user.id),
    )


@router.post("", response_model=WeightEntryRead, status_code=201)
def log_weight(
    payload: WeightEntryCreate,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> WeightEntryRead:
    recorded_on = payload.recorded_on or date.today()

    if recorded_on > date.today():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot record a weight for a future date.",
        )

    entry = weight_repo.add(
        db,
        user_id=user.id,
        weight_kg=payload.weight_kg,
        recorded_on=recorded_on,
        note=payload.note,
    )
    return WeightEntryRead.model_validate(entry)


@router.delete("/{entry_id}", status_code=204)
def delete_entry(
    entry_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> None:
    entry = weight_repo.get_owned(db, entry_id, user.id)
    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That entry does not exist.",
        )
    weight_repo.delete(db, entry)