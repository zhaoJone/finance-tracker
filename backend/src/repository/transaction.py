"""
Transaction repository - SQLAlchemy async CRUD operations.
"""
from datetime import date
from uuid import UUID

from sqlalchemy import delete as sql_delete, select, update as sql_update
from sqlalchemy.ext.asyncio import AsyncSession

from src.repository.models import TransactionTable
from src.schemas import Transaction


class TransactionRepository:
    """Async SQLAlchemy repository for transactions."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(self, tx: Transaction) -> Transaction:
        """Insert a new transaction."""
        row = TransactionTable(
            id=str(tx.id),
            amount=tx.amount,
            category_id=str(tx.category_id),
            note=tx.note,
            date=tx.date,
            type=tx.type,
            created_at=tx.created_at,
        )
        self._session.add(row)
        await self._session.flush()
        return tx

    async def get(self, id: UUID) -> Transaction | None:
        """Get a transaction by id."""
        stmt = select(TransactionTable).where(TransactionTable.id == str(id))
        result = await self._session.execute(stmt)
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return self._row_to_tx(row)

    async def list(
        self,
        start_date: date | None = None,
        end_date: date | None = None,
        category_id: UUID | None = None,
        tx_type: str | None = None,
    ) -> list[Transaction]:
        """List transactions with optional filters."""
        stmt = select(TransactionTable)

        if start_date is not None:
            stmt = stmt.where(TransactionTable.date >= start_date)
        if end_date is not None:
            stmt = stmt.where(TransactionTable.date <= end_date)
        if category_id is not None:
            stmt = stmt.where(TransactionTable.category_id == str(category_id))
        if tx_type is not None:
            stmt = stmt.where(TransactionTable.type == tx_type)

        stmt = stmt.order_by(TransactionTable.date.desc(), TransactionTable.created_at.desc())
        result = await self._session.execute(stmt)
        rows = result.scalars().all()
        return [self._row_to_tx(row) for row in rows]

    async def update(self, tx: Transaction) -> Transaction | None:
        """Update an existing transaction."""
        stmt = (
            sql_update(TransactionTable)
            .where(TransactionTable.id == str(tx.id))
            .values(
                amount=tx.amount,
                category_id=str(tx.category_id),
                note=tx.note,
                date=tx.date,
                type=tx.type,
            )
        )
        result = await self._session.execute(stmt)
        await self._session.flush()
        if result.rowcount == 0:  # type: ignore[attr-defined]
            return None
        return tx

    async def delete(self, id: UUID) -> bool:
        """Delete a transaction by id. Returns True if deleted."""
        stmt = sql_delete(TransactionTable).where(TransactionTable.id == str(id))
        result = await self._session.execute(stmt)
        await self._session.flush()
        return bool(result.rowcount)  # type: ignore[attr-defined]

    def _row_to_tx(self, row: TransactionTable) -> Transaction:
        """Convert a database row to a Transaction."""
        return Transaction(
            id=UUID(row.id),
            amount=row.amount,
            category_id=UUID(row.category_id),
            note=row.note or "",
            date=row.date,
            type=row.type,  # type: ignore[arg-type]
            created_at=row.created_at,
        )
