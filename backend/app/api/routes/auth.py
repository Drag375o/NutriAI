"""Authentication and account endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import current_user
from app.core.security import create_access_token, verify_password
from app.db.session import get_db
from app.models.user import User
from app.repositories import user_repo
from app.schemas.user import (
    AccountAction,
    PasswordChange,
    TokenResponse,
    UserLogin,
    UserRead,
    UserRegister,
)

router = APIRouter(prefix="/auth", tags=["auth"])

# Same message whether the email is unknown or the password is wrong, so
# the endpoint cannot be used to discover which addresses are registered.
_INVALID = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Email or password is incorrect.",
)


def _authenticate(db: Session, email: str, password: str) -> User:
    """Verify credentials, or raise. Does not check account status."""
    user = user_repo.get_by_email(db, email)
    if user is None or not verify_password(password, user.password_hash):
        raise _INVALID
    return user


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
    user = _authenticate(db, payload.email, payload.password)

    # An administrator's ban is checked first and is not something the
    # account holder can clear by signing in.
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been disabled. Contact support.",
        )

    # A self-paused account returns 423 rather than an error, so the app
    # can offer to restore it instead of only reporting a failure.
    if user.deactivated_at is not None:
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail="This account is deactivated.",
        )

    user_repo.touch_login(db, user)
    return TokenResponse(
        access_token=create_access_token(user.id, user.role),
        user=UserRead.model_validate(user),
    )


@router.post("/reactivate", response_model=TokenResponse)
def reactivate(payload: UserLogin, db: Session = Depends(get_db)) -> TokenResponse:
    """Restore a paused account and sign in.

    Credentials are verified again rather than trusted from the failed
    login, so knowing an email address is not enough to reactivate someone
    else's account.
    """
    user = _authenticate(db, payload.email, payload.password)

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been disabled. Contact support.",
        )

    user_repo.reactivate(db, user)
    user_repo.touch_login(db, user)

    return TokenResponse(
        access_token=create_access_token(user.id, user.role),
        user=UserRead.model_validate(user),
    )


@router.get("/me", response_model=UserRead)
def me(user: User = Depends(current_user)) -> UserRead:
    """Who am I. Used at startup to check a stored token is still good."""
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


@router.post("/deactivate", status_code=204)
def deactivate_account(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> None:
    """Pause the account. Everything is preserved; signing in restores it."""
    user_repo.deactivate(db, user)


@router.post("/delete", status_code=204)
def delete_account(
    payload: AccountAction,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> None:
    """Permanently remove the account and everything it owns.

    The password is required because this cannot be undone, and a token
    alone only proves the browser is signed in, not that the person at the
    keyboard is the account holder.
    """
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="That password is not correct.",
        )
    user_repo.delete(db, user)