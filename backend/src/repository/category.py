"""
Category repository - SQLAlchemy async CRUD operations.
"""
from uuid import UUID

from sqlalchemy import delete as sql_delete, func, select, update as sql_update
from sqlalchemy.ext.asyncio import AsyncSession

from src.repository.models import CategoryTable, TransactionTable
from src.schemas import Category


class CategoryRepository:
    """Async SQLAlchemy repository for categories."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(self, category: Category) -> Category:
        """Insert a new category."""
        row = CategoryTable(
            id=str(category.id),
            name=category.name,
            color=category.color,
            type=category.type,
            user_id=str(category.user_id),
        )
        self._session.add(row)
        await self._session.flush()
        return category

    async def get(self, id: UUID, user_id: str | None = None) -> Category | None:
        """Get a category by id, optionally scoped to a user."""
        stmt = select(CategoryTable).where(CategoryTable.id == str(id))
        if user_id is not None:
            stmt = stmt.where(CategoryTable.user_id == str(user_id))
        result = await self._session.execute(stmt)
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return self._row_to_category(row)

    async def list(self, user_id: str | None = None) -> list[Category]:
        """List all categories, optionally filtered by user."""
        stmt = select(CategoryTable).order_by(CategoryTable.name)
        if user_id is not None:
            stmt = stmt.where(CategoryTable.user_id == str(user_id))
        result = await self._session.execute(stmt)
        rows = result.scalars().all()
        return [self._row_to_category(row) for row in rows]

    async def update(self, category: Category) -> Category | None:
        """Update an existing category."""
        stmt = (
            sql_update(CategoryTable)
            .where(CategoryTable.id == str(category.id))
            .values(name=category.name, color=category.color, type=category.type)
        )
        result = await self._session.execute(stmt)
        await self._session.flush()
        if result.rowcount == 0:  # type: ignore[attr-defined]
            return None
        return category

    async def delete(self, id: UUID) -> bool:
        """Delete a category by id. Returns True if deleted."""
        stmt = sql_delete(CategoryTable).where(CategoryTable.id == str(id))
        result = await self._session.execute(stmt)
        await self._session.flush()
        return bool(result.rowcount)  # type: ignore[attr-defined]

    async def count_transactions(self, id: UUID) -> int:
        """Count transactions linked to this category."""
        stmt = select(func.count()).select_from(TransactionTable).where(
            TransactionTable.category_id == str(id)
        )
        result = await self._session.execute(stmt)
        return result.scalar() or 0

    def _row_to_category(self, row: CategoryTable) -> Category:
        """Convert a database row to a Category."""
        return Category(
            id=UUID(row.id),
            name=row.name,
            color=row.color,
            type=row.type,  # type: ignore[arg-type]
            user_id=UUID(row.user_id),
        )
