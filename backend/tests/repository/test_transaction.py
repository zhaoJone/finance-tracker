"""
Tests for TransactionRepository.
"""
from datetime import date, datetime
from uuid import uuid4

import aiosqlite
import pytest
import pytest_asyncio

from src.repository.transaction import TransactionRepository
from src.schemas import Transaction


@pytest_asyncio.fixture
async def db() -> aiosqlite.Connection:
    """Create an in-memory SQLite database with schema."""
    conn = await aiosqlite.connect(":memory:")
    conn.row_factory = aiosqlite.Row
    await conn.execute(
        """
        CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            amount INTEGER NOT NULL,
            category_id TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL,
            type TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    await conn.commit()
    yield conn
    await conn.close()


@pytest.fixture
def repo(db: aiosqlite.Connection) -> TransactionRepository:
    return TransactionRepository(db)


def make_tx(
    override: dict | None = None,
) -> Transaction:
    now = datetime(2026, 1, 1, 12, 0, 0)
    tx = Transaction(
        id=uuid4(),
        amount=1000,
        category_id=uuid4(),
        note="test",
        date=date(2026, 1, 1),
        type="income",
        created_at=now,
    )
    if override:
        tx = Transaction(**{**tx.model_dump(), **override})
    return tx


class TestTransactionRepositoryCreate:
    @pytest.mark.asyncio
    async def test_create_returns_transaction(self, repo: TransactionRepository) -> None:
        tx = make_tx()
        result = await repo.create(tx)
        assert result.id == tx.id
        assert result.amount == tx.amount

    @pytest.mark.asyncio
    async def test_create_persists_to_db(self, repo: TransactionRepository) -> None:
        tx = make_tx()
        await repo.create(tx)
        stored = await repo.get(tx.id)
        assert stored is not None
        assert stored.id == tx.id
        assert stored.amount == tx.amount


class TestTransactionRepositoryGet:
    @pytest.mark.asyncio
    async def test_get_existing(self, repo: TransactionRepository) -> None:
        tx = make_tx()
        await repo.create(tx)
        result = await repo.get(tx.id)
        assert result is not None
        assert result.id == tx.id

    @pytest.mark.asyncio
    async def test_get_nonexistent(self, repo: TransactionRepository) -> None:
        result = await repo.get(uuid4())
        assert result is None


class TestTransactionRepositoryList:
    @pytest.mark.asyncio
    async def test_list_empty(self, repo: TransactionRepository) -> None:
        result = await repo.list()
        assert result == []

    @pytest.mark.asyncio
    async def test_list_all(self, repo: TransactionRepository) -> None:
        for _ in range(3):
            await repo.create(make_tx())
        result = await repo.list()
        assert len(result) == 3

    @pytest.mark.asyncio
    async def test_list_by_date_range(self, repo: TransactionRepository) -> None:
        await repo.create(make_tx({"date": date(2026, 1, 1)}))
        await repo.create(make_tx({"date": date(2026, 2, 1)}))
        await repo.create(make_tx({"date": date(2026, 3, 1)}))

        result = await repo.list(
            start_date=date(2026, 1, 1), end_date=date(2026, 2, 28)
        )
        assert len(result) == 2

    @pytest.mark.asyncio
    async def test_list_by_category_id(self, repo: TransactionRepository) -> None:
        cat_id = uuid4()
        await repo.create(make_tx({"category_id": cat_id}))
        await repo.create(make_tx({"category_id": cat_id}))
        await repo.create(make_tx({"category_id": uuid4()}))

        result = await repo.list(category_id=cat_id)
        assert len(result) == 2

    @pytest.mark.asyncio
    async def test_list_by_type(self, repo: TransactionRepository) -> None:
        await repo.create(make_tx({"type": "income"}))
        await repo.create(make_tx({"type": "income"}))
        await repo.create(make_tx({"type": "expense"}))

        result = await repo.list(tx_type="expense")
        assert len(result) == 1
        assert result[0].type == "expense"

    @pytest.mark.asyncio
    async def test_list_combined_filters(self, repo: TransactionRepository) -> None:
        cat_id = uuid4()
        await repo.create(make_tx({"category_id": cat_id, "type": "income", "date": date(2026, 1, 15)}))
        await repo.create(make_tx({"category_id": cat_id, "type": "expense", "date": date(2026, 1, 15)}))
        await repo.create(make_tx({"category_id": cat_id, "type": "income", "date": date(2026, 2, 15)}))

        result = await repo.list(
            category_id=cat_id,
            tx_type="income",
            start_date=date(2026, 1, 1),
            end_date=date(2026, 1, 31),
        )
        assert len(result) == 1
        assert result[0].type == "income"


class TestTransactionRepositoryUpdate:
    @pytest.mark.asyncio
    async def test_update_existing(self, repo: TransactionRepository) -> None:
        tx = make_tx({"amount": 1000})
        await repo.create(tx)
        updated = tx.model_copy(update={"amount": 2000})
        result = await repo.update(updated)
        assert result is not None
        assert result.amount == 2000

    @pytest.mark.asyncio
    async def test_update_nonexistent(self, repo: TransactionRepository) -> None:
        tx = make_tx()
        result = await repo.update(tx)
        assert result is None


class TestTransactionRepositoryDelete:
    @pytest.mark.asyncio
    async def test_delete_existing(self, repo: TransactionRepository) -> None:
        tx = make_tx()
        await repo.create(tx)
        result = await repo.delete(tx.id)
        assert result is True
        assert await repo.get(tx.id) is None

    @pytest.mark.asyncio
    async def test_delete_nonexistent(self, repo: TransactionRepository) -> None:
        result = await repo.delete(uuid4())
        assert result is False
