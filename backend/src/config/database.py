"""
Database configuration and session management.
"""
from collections.abc import AsyncGenerator
from typing import Annotated, Any

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

DATABASE_URL: str | None = None

_engine: Any = None
_session_factory: Any = None


def get_database_url() -> str:
    """Get DATABASE_URL from environment or return default."""
    global DATABASE_URL
    if DATABASE_URL is None:
        import os
        DATABASE_URL = os.getenv(
            "DATABASE_URL",
            "postgresql+asyncpg://postgres:mysecretpassword@127.0.0.1:5432/finance_tracker",
        )
    return DATABASE_URL


def get_engine() -> Any:
    """Get or create the async engine."""
    global _engine
    if _engine is None:
        _engine = create_async_engine(
            get_database_url(),
            echo=False,
            poolclass=NullPool,
        )
    return _engine


def get_session_factory() -> Any:
    """Get or create the session factory."""
    global _session_factory
    if _session_factory is None:
        _session_factory = async_sessionmaker(
            bind=get_engine(),
            class_=AsyncSession,
            expire_on_commit=False,
        )
    return _session_factory


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency injection for FastAPI - yields an async SQLAlchemy session."""
    factory = get_session_factory()
    async with factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


DbSession = Annotated[AsyncSession, Depends(get_db)]
