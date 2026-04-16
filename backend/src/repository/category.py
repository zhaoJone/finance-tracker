"""
Category repository - SQLite CRUD operations.
"""
from typing import Any
from uuid import UUID

from src.schemas import Category


class CategoryRepository:
    """Async SQLite repository for categories."""

    def __init__(self, db: Any) -> None:
        self._db = db

    async def create(self, category: Category) -> Category:
        """Insert a new category."""
        await self._db.execute(
            """
            INSERT INTO categories (id, name, color, type)
            VALUES (?, ?, ?, ?)
            """,
            (str(category.id), category.name, category.color, category.type),
        )
        await self._db.commit()
        return category

    async def get(self, id: UUID) -> Category | None:
        """Get a category by id."""
        cursor = await self._db.execute(
            "SELECT * FROM categories WHERE id = ?", (str(id),)
        )
        row = await cursor.fetchone()
        if row is None:
            return None
        return self._row_to_category(row)

    async def list(self) -> list[Category]:
        """List all categories."""
        cursor = await self._db.execute(
            "SELECT * FROM categories ORDER BY name"
        )
        rows = await cursor.fetchall()
        return [self._row_to_category(row) for row in rows]

    async def update(self, category: Category) -> Category | None:
        """Update an existing category."""
        cursor = await self._db.execute(
            """
            UPDATE categories
            SET name = ?, color = ?, type = ?
            WHERE id = ?
            """,
            (category.name, category.color, category.type, str(category.id)),
        )
        await self._db.commit()
        if cursor.rowcount == 0:
            return None
        return category

    async def delete(self, id: UUID) -> bool:
        """Delete a category by id. Returns True if deleted."""
        cursor = await self._db.execute(
            "DELETE FROM categories WHERE id = ?", (str(id),)
        )
        await self._db.commit()
        return bool(cursor.rowcount)

    def _row_to_category(self, row: Any) -> Category:
        """Convert a database row to a Category."""
        return Category(
            id=UUID(row[0]),
            name=row[1],
            color=row[2],
            type=row[3],
        )
