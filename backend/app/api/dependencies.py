"""Shared route dependencies: who is calling, and may they."""

from fastapi import Depends, HTTPException, Query, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.user import User
from app.repositories import user_repo

_bearer = HTTPBearer(auto_error=False)

_UNAUTHORIZED = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Not signed in.",
    headers={"WWW-Authenticate": "Bearer"},
)


def _user_from_token(token: str, db: Session) -> User:
    """Verify a token and return its user, or raise 401.

    Shared by both entry points so the checks cannot drift apart.
    """
    payload = decode_access_token(token)
    if payload is None or "sub" not in payload:
        raise _UNAUTHORIZED

    user = user_repo.get_by_id(db, int(payload["sub"]))
    if user is None or not user.is_active:
        raise _UNAUTHORIZED

    return user


def current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    """The signed-in user, or 401.

    Deactivated accounts are rejected here, so disabling an account takes
    effect immediately even if the holder still has a valid token.
    """
    if credentials is None:
        raise _UNAUTHORIZED

    return _user_from_token(credentials.credentials, db)


def current_user_from_query(
    token: str = Query(..., description="Access token"),
    db: Session = Depends(get_db),
) -> User:
    """The signed-in user, from a query parameter rather than a header.

    Only for browser downloads, which cannot set an Authorization header.
    The token is still verified and ownership is still checked; the tradeoff
    is that it appears in browser history and server logs, so this is used
    nowhere else.
    """
    return _user_from_token(token, db)


def current_admin(user: User = Depends(current_user)) -> User:
    """Admins only.

    Role is read from the database, not from the token, so revoking admin
    takes effect immediately rather than when the token expires.
    """
    if user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator access required.",
        )
    return user