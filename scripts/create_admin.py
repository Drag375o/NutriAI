"""Create an administrator account.

Run from the project root:
    python scripts/create_admin.py

Requires ADMIN_CREATION_SECRET from .env. There is deliberately no API
endpoint for this: an admin can only be created by someone with access to
this machine and the secret.
"""

import getpass
import sys
from pathlib import Path

# Make the backend package importable when run from the project root.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "backend"))

from app.core.config import settings  # noqa: E402
from app.db.session import SessionLocal, init_db  # noqa: E402
from app.repositories import user_repo  # noqa: E402

LINE = "-" * 52


def secret_input(prompt: str) -> str:
    """Read a password with no echo at all.

    Nothing appears as you type - not even asterisks - so a bystander
    learns neither the password nor its length. A character count is
    printed afterwards so you can confirm the keystrokes registered.
    """
    value = getpass.getpass(prompt)
    print(f"  ({len(value)} characters entered)")
    return value


def ask(label: str, hint: str = "") -> str:
    """Prompt for a visible value, showing what is expected."""
    if hint:
        print(f"  {hint}")
    return input(f"  {label}: ").strip()


def main() -> int:
    print()
    print(LINE)
    print("  NutriAI - create an administrator account")
    print(LINE)
    print()

    if not settings.ADMIN_CREATION_SECRET:
        print("  ADMIN_CREATION_SECRET is not set in .env. Aborting.\n")
        return 1

    print("  Step 1 of 4 - authorisation")
    print("  The company password is required to create an admin.")
    print("  Nothing will appear on screen while you type it.")
    print()

    secret = secret_input("  Company password: ")
    if secret != settings.ADMIN_CREATION_SECRET:
        print("\n  Incorrect company password. Nothing was created.\n")
        return 1

    print("  Authorised.\n")

    print("  Step 2 of 4 - email")
    email = ask("Email", "Used to sign in. Must not already have an account.")
    if not email or "@" not in email:
        print("\n  That does not look like an email address.\n")
        return 1
    print()

    print("  Step 3 of 4 - name")
    name = ask("Name", "Shown in the admin panel.")
    if not name:
        print("\n  Name is required.\n")
        return 1
    print()

    print("  Step 4 of 4 - password")
    print("  At least 8 characters. Nobody, including other admins,")
    print("  will ever be able to read it back.")
    print()

    password = secret_input("  Password: ")
    if len(password) < 8:
        print("\n  Password must be at least 8 characters.\n")
        return 1

    confirm = secret_input("  Confirm password: ")
    if password != confirm:
        print("\n  Passwords do not match. Nothing was created.\n")
        return 1

    print()
    init_db()
    db = SessionLocal()
    try:
        if user_repo.get_by_email(db, email):
            print(f"  An account already exists for {email}.\n")
            return 1

        admin = user_repo.create(
            db, email=email, name=name, password=password, role="admin"
        )

        print(LINE)
        print("  Administrator created")
        print(LINE)
        print(f"  id     {admin.id}")
        print(f"  name   {admin.name}")
        print(f"  email  {admin.email}")
        print(f"  role   {admin.role}")
        print(LINE)
        print("  Sign in at the normal login screen.")
        print()
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\n\n  Cancelled. Nothing was created.\n")
        raise SystemExit(130)