"""
Alembic migration utilities for programmatic migration execution.
"""
from alembic import context
from alembic.config import Config
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from src.repository.models import Base


def get_alembic_config() -> Config:
    """Get Alembic configuration."""
    import os
    cfg_path = os.getenv("ALEMBIC_INI", "/opt/data/home/finance-tracker/backend/alembic.ini")
    cfg = Config(file_=cfg_path)
    return cfg


def get_url() -> str:
    """Get DATABASE_URL from environment variable."""
    import os
    return os.getenv(
        "DATABASE_URL",
        "postgresql+asyncpg://postgres:mysecretpassword@127.0.0.1:5432/finance_tracker",
    )


async def run_migrations_online() -> None:
    """Run migrations in 'online' mode using async engine."""
    configuration = {
        "sqlalchemy.url": get_url(),
    }

    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def do_run_migrations(connection: Connection) -> None:
    """Run migrations with the given connection."""
    context.configure(
        connection=connection,
        target_metadata=Base.metadata,
    )

    with context.begin_transaction():
        context.run_migrations()


def upgrade_head() -> None:
    """Run alembic upgrade head programmatically."""
    import asyncio
    try:
        asyncio.get_running_loop()
        # Already in async context, schedule the migration
        async def _upgrade() -> None:
            await run_migrations_online()
        asyncio.create_task(_upgrade())
    except RuntimeError:
        # No running loop
        asyncio.run(run_migrations_online())
