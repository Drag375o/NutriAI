"""Authentication endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import current_user
from app.core.security import create_access_token, verify_password
from app.db.session import get_db
from app.models.user import User
from app.repositories import user_repo
from app.schemas.user import (
    PasswordChange,
    TokenResponse,
    UserLogin,
    UserRead,
    UserRegister,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
def register(payload: UserRegister, db: Session = Depends(get_db)) -> TokenResponse:
    """Open registration. Always creates a normal user.

    Role is hardcoded here rather than read from the request, so no amount
    of crafting a payload can produce an admin account.
    """
    if user_repo.get_by_email(db, payload.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with that email already exists.",
        )

    user = user_repo.create(
        db, email=payload.email, name=payload.name, password=payload.password
    )
    return TokenResponse(
        access_token=create_access_token(user.id, user.role),
        user=UserRead.model_validate(user),
    )


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, db: Session = Depends(get_db)) -> TokenResponse:
    """One login for everyone. Role in the response decides what the app shows."""
    user = user_repo.get_by_email(db, payload.email)

    # Same message whether the email is unknown or the password is wrong,
    # so the endpoint cannot be used to discover which emails are registered.
    invalid = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Email or password is incorrect.",
    )

    if user is None or not verify_password(payload.password, user.password_hash):
        raise invalid
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated.",
        )

    user_repo.touch_login(db, user)
    return TokenResponse(
        access_token=create_access_token(user.id, user.role),
        user=UserRead.model_validate(user),
    )


@router.get("/me", response_model=UserRead)
def me(user: User = Depends(current_user)) -> UserRead:
    """Who am I. Used by the app on startup to check a stored token is still good."""
    return UserRead.model_validate(user)


@router.post("/change-password", status_code=204)
def change_password(
    payload: PasswordChange,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> None:
    """Change your own password.

    The current password is hashed and compared, never read. This is why a
    password can be changed without anyone being able to see it.
    """
    if not verify_password(payload.current_password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect.",
        )
    user_repo.set_password(db, user, payload.new_password)