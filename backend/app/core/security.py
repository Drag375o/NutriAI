"""Password hashing and JWT tokens.

Passwords are hashed with bcrypt, which is one-way: the stored value cannot
be turned back into the password. Nobody can read a user's password, including
an administrator with full database access. That is deliberate and correct.

Uses the bcrypt library directly rather than passlib, which is unmaintained
and incompatible with current bcrypt releases.
"""

from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt

from app.core.config import settings

# bcrypt hashes at most 72 bytes and silently ignores the rest. Truncating
# here makes that limit explicit rather than leaving it as a hidden surprise.
_MAX_BYTES = 72


def _encode(password: str) -> bytes:
    return password.encode("utf-8")[:_MAX_BYTES]


def hash_password(plain: str) -> str:
    """One-way hash. The result is safe to store.

    gensalt() embeds a random salt in the output, so two people with the
    same password get different hashes and one cracked hash reveals nothing
    about the others.
    """
    return bcrypt.hashpw(_encode(plain), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """Hash the attempt and compare. The stored hash is never reversed."""
    try:
        return bcrypt.checkpw(_encode(plain), hashed.encode("utf-8"))
    except ValueError:
        # Malformed hash in the database. Treat as a failed login, not a crash.
        return False


def create_access_token(user_id: int, role: str) -> str:
    """Signed token proving who the bearer is.

    Carries only the user id and role. No personal data, because anyone
    holding the token can read its contents; they just cannot alter them
    without the signing secret.
    """
    expires = datetime.now(timezone.utc) + timedelta(days=settings.JWT_EXPIRE_DAYS)
    payload = {"sub": str(user_id), "role": role, "exp": expires}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> dict | None:
    """Verify signature and expiry. Returns None on anything invalid."""
    try:
        return jwt.decode(
            token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM]
        )
    except JWTError:
        return None