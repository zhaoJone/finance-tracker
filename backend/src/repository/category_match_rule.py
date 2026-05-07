"""
CategoryMatchRule repository - SQLAlchemy async CRUD operations.
"""
from uuid import UUID

from sqlalchemy import delete as sql_delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.repository.models import CategoryMatchRuleTable
from src.schemas.category_match_rule import CategoryMatchRule


class CategoryMatchRuleRepository:
    """Async SQLAlchemy repository for category match rules."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(self, rule: CategoryMatchRule) -> CategoryMatchRule:
        """Insert a new match rule."""
        row = CategoryMatchRuleTable(
            id=str(rule.id),
            user_id=str(rule.user_id),
            keyword=rule.keyword,
            category_id=str(rule.category_id),
            created_at=rule.created_at,
        )
        self._session.add(row)
        await self._session.flush()
        return rule

    async def list(self, user_id: str) -> list[CategoryMatchRule]:
        """List all match rules for a user."""
        stmt = (
            select(CategoryMatchRuleTable)
            .where(CategoryMatchRuleTable.user_id == user_id)
            .order_by(CategoryMatchRuleTable.created_at.desc())
        )
        result = await self._session.execute(stmt)
        rows = result.scalars().all()
        return [self._row_to_rule(row) for row in rows]

    async def find_by_keyword(self, user_id: str, keyword: str) -> CategoryMatchRule | None:
        """Find a match rule by keyword for a user."""
        stmt = select(CategoryMatchRuleTable).where(
            CategoryMatchRuleTable.user_id == user_id,
            CategoryMatchRuleTable.keyword == keyword,
        )
        result = await self._session.execute(stmt)
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return self._row_to_rule(row)

    async def match_by_keyword(self, user_id: str, keyword: str) -> CategoryMatchRule | None:
        """Find a rule by keyword (exact match first, then partial)."""
        # Exact match
        stmt = select(CategoryMatchRuleTable).where(
            CategoryMatchRuleTable.user_id == user_id,
            CategoryMatchRuleTable.keyword == keyword,
        )
        result = await self._session.execute(stmt)
        row = result.scalar_one_or_none()
        if row is not None:
            return self._row_to_rule(row)

        # Partial match: keyword is contained in merchant name
        stmt = select(CategoryMatchRuleTable).where(
            CategoryMatchRuleTable.user_id == user_id,
        )
        result = await self._session.execute(stmt)
        rows = result.scalars().all()
        for row in rows:
            if row.keyword in keyword.replace(" ", ""):
                return self._row_to_rule(row)

        return None

    async def delete(self, id: UUID, user_id: str) -> bool:
        """Delete a match rule (user-scoped)."""
        stmt = (
            sql_delete(CategoryMatchRuleTable)
            .where(
                CategoryMatchRuleTable.id == str(id),
                CategoryMatchRuleTable.user_id == user_id,
            )
        )
        result = await self._session.execute(stmt)
        await self._session.flush()
        return bool(result.rowcount)  # type: ignore[attr-defined]

    def _row_to_rule(self, row: CategoryMatchRuleTable) -> CategoryMatchRule:
        """Convert a database row to a CategoryMatchRule."""
        return CategoryMatchRule(
            id=UUID(row.id),
            user_id=UUID(row.user_id),
            keyword=row.keyword,
            category_id=UUID(row.category_id),
            created_at=row.created_at,
        )
