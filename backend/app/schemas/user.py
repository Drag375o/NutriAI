"""Request and response shapes for accounts."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserRegister(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=80)
    # Eight characters is a floor, not a target. Length beats complexity rules.
    password: str = Field(min_length=8, max_length=128)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class PasswordChange(BaseModel):
    """Requires the current password, which proves identity without reading it."""

    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


class UserRead(BaseModel):
    """Safe to return. Contains no credential material of any kind."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    name: str
    role: str
    is_active: bool
    must_change_password: bool
    deactivated_at: datetime | None = None    
    created_at: datetime
    last_login_at: datetime | None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead


class AccountAction(BaseModel):
    """Deleting requires the password, which proves identity rather than
    just testing whether someone can click."""

    password: str


class DeactivatedResponse(BaseModel):
    """Returned when someone signs in to a paused account.

    A distinct shape rather than a plain error, so the app can offer to
    restore rather than only reporting a failure.
    """

    detail: str = "This account is deactivated."
    deactivated: bool = True