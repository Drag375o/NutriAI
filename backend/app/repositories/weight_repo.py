"""Database access for weight entries."""

from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.profile import Profile
from app.models.weight_entry import WeightEntry
from app.schemas.weight_entry import WeightTrend

# How far back "recent change" looks. A week is long enough to see past
# daily fluctuation and short enough to still feel current.
RECENT_DAYS = 7


def list_for_user(
    db: Session, user_id: int, limit: int = 365
) -> list[WeightEntry]:
    """Entries oldest first, which is the order a chart draws them in."""
    rows = list(
        db.scalars(
            select(WeightEntry)
            .where(WeightEntry.user_id == user_id)
            .order_by(WeightEntry.recorded_on.desc())
            .limit(limit)
        )
    )
    return list(reversed(rows))


def get_owned(db: Session, entry_id: int, user_id: int) -> WeightEntry | None:
    """Ownership is part of the query, not a check afterwards."""
    return db.scalar(
        select(WeightEntry).where(
            WeightEntry.id == entry_id,
            WeightEntry.user_id == user_id,
        )
    )


def add(
    db: Session,
    *,
    user_id: int,
    weight_kg: float,
    recorded_on: date,
    note: str | None,
) -> WeightEntry:
    """Record a weigh-in, replacing any existing entry for that date.

    One entry per day: a second weigh-in on the same morning corrects the
    first rather than adding a point to the chart.
    """
    existing = db.scalar(
        select(WeightEntry).where(
            WeightEntry.user_id == user_id,
            WeightEntry.recorded_on == recorded_on,
        )
    )
    if existing is not None:
        db.delete(existing)
        db.flush()

    entry = WeightEntry(
        user_id=user_id,
        weight_kg=weight_kg,
        recorded_on=recorded_on,
        note=note,
    )
    db.add(entry)
    db.flush()

    _sync_profile(db, user_id)
    db.commit()
    db.refresh(entry)
    return entry


def delete(db: Session, entry: WeightEntry) -> None:
    user_id = entry.user_id
    db.delete(entry)
    db.flush()

    _sync_profile(db, user_id)
    db.commit()


def _sync_profile(db: Session, user_id: int) -> None:
    """Copy the most recent weight onto the profile.

    The entries are the record; profile.weight_kg is a cached 'current' so
    BMI, BMR and the calorie target do not need a subquery on every read.
    Updated on every write here so the two can never disagree.
    """
    latest = db.scalar(
        select(WeightEntry)
        .where(WeightEntry.user_id == user_id)
        .order_by(WeightEntry.recorded_on.desc())
        .limit(1)
    )

    profile = db.scalar(select(Profile).where(Profile.user_id == user_id))
    if profile is None:
        return

    # Deleting the last entry leaves the profile weight as it was rather
    # than nulling it, since BMI disappearing would be more surprising
    # than a slightly stale number.
    if latest is not None:
        profile.weight_kg = latest.weight_kg


def backfill_from_profile(db: Session, user_id: int) -> None:
    """Seed the history from the profile weight, for accounts that predate
    weight tracking.

    Without this their chart would be empty despite a weight being on
    screen everywhere else. Runs once: it does nothing if any entry exists.
    """
    has_any = db.scalar(
        select(WeightEntry.id).where(WeightEntry.user_id == user_id).limit(1)
    )
    if has_any is not None:
        return

    profile = db.scalar(select(Profile).where(Profile.user_id == user_id))
    if profile is None or profile.weight_kg is None:
        return

    db.add(
        WeightEntry(
            user_id=user_id,
            weight_kg=profile.weight_kg,
            recorded_on=date.today(),
            note="From your profile",
        )
    )
    db.commit()


def trend(db: Session, user_id: int) -> WeightTrend:
    """Summarise the history for the Progress screen."""
    entries = list_for_user(db, user_id)

    if not entries:
        profile = db.scalar(select(Profile).where(Profile.user_id == user_id))
        return WeightTrend(target=profile.target_weight_kg if profile else None)

    first = entries[0]
    last = entries[-1]

    profile = db.scalar(select(Profile).where(Profile.user_id == user_id))
    target = profile.target_weight_kg if profile else None

    # The earliest entry within the recent window, so "recent change" is
    # measured against roughly a week ago rather than the entry before it.
    cutoff = last.recorded_on - timedelta(days=RECENT_DAYS)
    in_window = [e for e in entries if e.recorded_on >= cutoff]
    recent_change = (
        round(last.weight_kg - in_window[0].weight_kg, 1)
        if len(in_window) > 1
        else None
    )

    return WeightTrend(
        latest=last.weight_kg,
        latest_on=last.recorded_on,
        starting=first.weight_kg,
        starting_on=first.recorded_on,
        target=target,
        total_change=round(last.weight_kg - first.weight_kg, 1)
        if len(entries) > 1
        else None,
        recent_change=recent_change,
        to_target=round(abs(last.weight_kg - target), 1) if target else None,
        entry_count=len(entries),
    )