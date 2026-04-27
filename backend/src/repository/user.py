"""
User repository - SQLAlchemy async CRUD operations.
"""
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.repository.models import UserTable
from src.schemas.user import User


class UserRepository:
    """Async SQLAlchemy repository for users."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(self, email: str, password_hash: str) -> User:
        """Create a new user."""
        row = UserTable(id=str(uuid4()), email=email, password_hash=password_hash)
        self._session.add(row)
        await self._session.flush()
        return User(id=UUID(row.id), email=row.email, created_at=row.created_at or datetime.now())

    async def get_by_email(self, email: str) -> User | None:
        """Get a user by email."""
        stmt = select(UserTable).where(UserTable.email == email)
        result = await self._session.execute(stmt)
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return User(id=UUID(row.id), email=row.email, created_at=row.created_at or datetime.now())

    async def get_by_id(self, user_id: str) -> User | None:
        """Get a user by id."""
        stmt = select(UserTable).where(UserTable.id == user_id)
        result = await self._session.execute(stmt)
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return User(id=UUID(row.id), email=row.email, created_at=row.created_at or datetime.now())
