"""Shapes for the administration endpoints.

An administrator manages accounts. They do not read the health data inside
them: no profile fields, no conversations, no plans appear here, and no
credential material of any kind.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class AdminUserRow(BaseModel):
    """One account in the list."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    name: str
    role: str
    is_active: bool
    deactivated_at: datetime | None
    created_at: datetime
    last_login_at: datetime | None

    # Counts rather than contents: enough to see whether an account is in
    # use, without exposing what it contains.
    conversation_count: int = 0
    plan_count: int = 0
    weight_entry_count: int = 0
    profile_complete: bool = False


class AdminStats(BaseModel):
    total_users: int = 0
    active_users: int = 0
    deactivated_users: int = 0
    disabled_users: int = 0
    admins: int = 0
    signed_in_this_week: int = 0


class AdminUserUpdate(BaseModel):
    """Only account status is editable. Names, emails and health details
    belong to the person, not the administrator."""

    is_active: bool | None = None


class TemporaryPassword(BaseModel):
    """Returned once, when an admin resets a password.

    This is a password the administrator has just generated, not the
    user's own, which remains unreadable.
    """

    temporary_password: str = Field(
        description="Shown once. The user must change it at next sign-in."
    )