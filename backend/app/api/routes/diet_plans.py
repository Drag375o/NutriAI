"""Diet plan endpoints."""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.ai.context import user_context
from app.ai.service import AIService
from app.api.dependencies import current_user, current_user_from_query
from app.db.session import get_db
from app.models.user import User
from app.repositories import diet_plan_repo, profile_repo
from app.schemas.diet_plan import DietPlanRead, DietPlanSummary, GenerateRequest

from app.services import diet_plan_service
from app.services.health_calc import (
    calculate_bmr,
    calculate_daily_calories,
)

from fastapi.responses import Response

from app.services import pdf_service


router = APIRouter(prefix="/diet-plans", tags=["diet plans"])

_service = AIService()


def _require_target(profile) -> int:
    """The calorie target this plan is built against.

    Generation is refused without one: a plan built on a guessed target is
    worse than no plan, and the profile is quick to complete.
    """
    if not (profile.height_cm and profile.weight_kg and profile.age):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Add your age, height and weight first so NutriAI knows "
            "what to aim for.",
        )

    bmr = calculate_bmr(
        profile.weight_kg, profile.height_cm, profile.age, profile.sex
    )
    return calculate_daily_calories(bmr, profile.activity_level, profile.goal)


@router.post("", response_model=DietPlanRead, status_code=201)
async def generate_plan(
    payload: GenerateRequest,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> DietPlanRead:
    profile = profile_repo.get_or_create(db, user.id)
    target = _require_target(profile)
    plan_date = payload.plan_date or date.today()

    # Reuse the chat context builder, asking it a food question so the
    # energy and activity sections are included.
    context = user_context.build(profile, "meal plan calories portion protein")

    try:
        generated = await diet_plan_service.generate(
            _service,
            target_calories=target,
            context=context,
            note=payload.note,
        )
    except diet_plan_service.DietPlanError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=e.message
        )

    plan = diet_plan_repo.save(
        db,
        user_id=user.id,
        plan_date=plan_date,
        target_calories=target,
        goal=profile.goal,
        generated=generated,
    )
    return DietPlanRead.model_validate(plan)


@router.get("/today", response_model=DietPlanRead | None)
def todays_plan(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> DietPlanRead | None:
    plan = diet_plan_repo.get_for_date(db, user.id, date.today())
    return None if plan is None else DietPlanRead.model_validate(plan)


@router.get("", response_model=list[DietPlanSummary])
def list_plans(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> list[DietPlanSummary]:
    return [
        DietPlanSummary.model_validate(p)
        for p in diet_plan_repo.list_for_user(db, user.id)
    ]


@router.get("/{plan_id}", response_model=DietPlanRead)
def read_plan(
    plan_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> DietPlanRead:
    plan = diet_plan_repo.get_owned(db, plan_id, user.id)
    if plan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That plan does not exist.",
        )
    return DietPlanRead.model_validate(plan)

@router.get("/{plan_id}/pdf")
def download_plan(
    plan_id: int,
    # Query-parameter auth, because a browser download is a plain
    # navigation and cannot carry an Authorization header.
    user: User = Depends(current_user_from_query),
    db: Session = Depends(get_db),
) -> Response:
    """The plan as a downloadable PDF."""
    plan = diet_plan_repo.get_owned(db, plan_id, user.id)
    if plan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That plan does not exist.",
        )

    pdf = pdf_service.render_plan(plan, name=user.name)
    filename = f"nutriai-plan-{plan.plan_date.isoformat()}.pdf"

    return Response(
        content=pdf,
        media_type="application/pdf",
        # attachment rather than inline, so the browser saves it rather
        # than opening a viewer tab.
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.delete("/{plan_id}", status_code=204)
def delete_plan(
    plan_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> None:
    plan = diet_plan_repo.get_owned(db, plan_id, user.id)
    if plan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That plan does not exist.",
        )
    diet_plan_repo.delete(db, plan)