"""
Transaction repository - SQLite CRUD operations.
"""
from datetime import date
from typing import Any
from uuid import UUID

import aiosqlite

from src.schemas import Transaction


class TransactionRepository:
    """Async SQLite repository for transactions."""

    def __init__(self, db: aiosqlite.Connection) -> None:
        self._db = db

    async def create(self, tx: Transaction) -> Transaction:
        """Insert a new transaction."""
        await self._db.execute(
            """
            INSERT INTO transactions (id, amount, category_id, note, date, type, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                str(tx.id),
                tx.amount,
                str(tx.category_id),
                tx.note,
                tx.date.isoformat(),
                tx.type,
                tx.created_at.isoformat(),
            ),
        )
        await self._db.commit()
        return tx

    async def get(self, id: UUID) -> Transaction | None:
        """Get a transaction by id."""
        cursor = await self._db.execute(
            "SELECT * FROM transactions WHERE id = ?", (str(id),)
        )
        row = await cursor.fetchone()
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
        where: list[str] = []
        params: list[Any] = []

        if start_date is not None:
            where.append("date >= ?")
            params.append(start_date.isoformat())
        if end_date is not None:
            where.append("date <= ?")
            params.append(end_date.isoformat())
        if category_id is not None:
            where.append("category_id = ?")
            params.append(str(category_id))
        if tx_type is not None:
            where.append("type = ?")
            params.append(tx_type)

        query = "SELECT * FROM transactions"
        if where:
            query += " WHERE " + " AND ".join(where)
        query += " ORDER BY date DESC, created_at DESC"

        cursor = await self._db.execute(query, params)
        rows = await cursor.fetchall()
        return [self._row_to_tx(row) for row in rows]

    async def update(self, tx: Transaction) -> Transaction | None:
        """Update an existing transaction."""
        cursor = await self._db.execute(
            """
            UPDATE transactions
            SET amount = ?, category_id = ?, note = ?, date = ?, type = ?
            WHERE id = ?
            """,
            (
                tx.amount,
                str(tx.category_id),
                tx.note,
                tx.date.isoformat(),
                tx.type,
                str(tx.id),
            ),
        )
        await self._db.commit()
        if cursor.rowcount == 0:
            return None
        return tx

    async def delete(self, id: UUID) -> bool:
        """Delete a transaction by id. Returns True if deleted."""
        cursor = await self._db.execute(
            "DELETE FROM transactions WHERE id = ?", (str(id),)
        )
        await self._db.commit()
        return bool(cursor.rowcount)

    def _row_to_tx(self, row: Any) -> Transaction:
        """Convert a database row to a Transaction."""
        from datetime import datetime

        return Transaction(
            id=UUID(row[0]),
            amount=row[1],
            category_id=UUID(row[2]),
            note=row[3],
            date=date.fromisoformat(row[4]),
            type=row[5],
            created_at=datetime.fromisoformat(row[6]),
        )
