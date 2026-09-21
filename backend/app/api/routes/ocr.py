"""Image text extraction.

Runs Tesseract locally, so an uploaded prescription never leaves this
machine. The extracted text is returned for review and is not stored.
"""

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.api.dependencies import current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories import profile_repo
from app.schemas.ocr import ConditionsUpdate, OcrResult, OcrStatus
from app.schemas.profile import ProfileRead
from app.services import ocr_service


router = APIRouter(prefix="/ocr", tags=["ocr"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}


@router.get("/status", response_model=OcrStatus)
def status_check(user: User = Depends(current_user)) -> OcrStatus:
    """Whether extraction is set up, so the UI can say so before an upload."""
    if ocr_service.is_available():
        return OcrStatus(available=True)

    return OcrStatus(
        available=False,
        reason="Text extraction is not set up on this machine.",
    )


@router.post("/extract", response_model=OcrResult)
async def extract_text(
    file: UploadFile = File(...),
    user: User = Depends(current_user),
) -> OcrResult:
    """Read text from an uploaded image.

    The image is processed in memory and discarded. Nothing is stored, and
    nothing is sent anywhere: the result goes back to the user to correct
    before any of it is used.
    """
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Upload a photograph or a scan: JPEG, PNG or WebP.",
        )

    content = await file.read()

    try:
        text = ocr_service.extract(content)
    except ocr_service.OcrError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=e.message
        )

    # Short or fragmented output usually means a poor photograph. Flagged
    # so the review screen can suggest retaking it rather than leaving the
    # user to correct a page of noise.
    likely_poor = len(text) < 60 or text.count("\n") > len(text) / 12

    return OcrResult(text=text, likely_poor=likely_poor)


@router.patch("/conditions", response_model=ProfileRead)
def save_conditions(
    payload: ConditionsUpdate,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> ProfileRead:
    """Store the conditions the user confirmed.

    A separate endpoint from PATCH /profile so the intent is visible in the
    API: this is the end of a review the user performed, not a field edit.
    """
    from app.api.routes.profile import _to_read

    updated = profile_repo.update(
        db, user.id, {"conditions": payload.conditions.strip()}
    )
    return _to_read(updated)