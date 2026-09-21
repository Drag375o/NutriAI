"""Alembic environment.

Reads the database URL and the model metadata from the application itself,
so migrations always run against the same database the app uses and
autogenerate sees every table.
"""

import sys
from logging.config import fileConfig
from pathlib import Path

from sqlalchemy import engine_from_config, pool

from alembic import context

# The backend package is one level up from this file's parent.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db.base import Base  # noqa: E402
from app.db.session import _url  # noqa: E402

# Importing the models registers them on Base.metadata. Without this,
# autogenerate would see an empty schema and try to drop every table.
from app.models import (  # noqa: E402,F401
    conversation,
    diet_plan,
    profile,
    user,
    weight_entry,
)

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Taken from the app's own settings rather than alembic.ini, so there is
# one definition of where the database lives.
config.set_main_option("sqlalchemy.url", _url)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Generate SQL without connecting, for review or manual application."""
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        # SQLite cannot ALTER most things in place; batch mode rebuilds the
        # table around the change instead.
        render_as_batch=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            # Required for SQLite: it supports almost no ALTER TABLE
            # operations, so Alembic recreates the table and copies the
            # data. Without this most migrations fail outright.
            render_as_batch=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()