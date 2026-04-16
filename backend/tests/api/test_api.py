"""
Tests for API routes using TestClient.
"""
import asyncio
import sqlite3
from datetime import datetime
from pathlib import Path
from uuid import uuid4

import aiosqlite
import pytest
import pytest_asyncio
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.categories import router as categories_router
from src.api.stats import router as stats_router
from src.api.transactions import router as transactions_router


class TestDB:
    """Shared test database connection using aiosqlite for app queries."""

    _conn: aiosqlite.Connection | None = None
    _sync_conn: sqlite3.Connection | None = None
    _db_path: Path | None = None

    @classmethod
    async def get_conn(cls) -> aiosqlite.Connection:
        """Get or create the async connection for the app."""
        if cls._conn is None:
            cls._db_path = Path(__file__).parent.parent.parent / "test.db"
            if cls._db_path.exists():
                cls._db_path.unlink()
            cls._conn = await aiosqlite.connect(str(cls._db_path))
            cls._conn.row_factory = aiosqlite.Row
            await cls._conn.execute("""
                CREATE TABLE IF NOT EXISTS transactions (
                    id TEXT PRIMARY KEY,
                    amount INTEGER NOT NULL,
                    category_id TEXT NOT NULL,
                    note TEXT NOT NULL DEFAULT '',
                    date TEXT NOT NULL,
                    type TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
            """)
            await cls._conn.execute("""
                CREATE TABLE IF NOT EXISTS categories (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    color TEXT NOT NULL,
                    type TEXT NOT NULL
                )
            """)
            await cls._conn.commit()
        return cls._conn

    @classmethod
    def _get_sync_conn(cls) -> sqlite3.Connection:
        """Get or create a synchronous connection for test seeding."""
        if cls._sync_conn is None:
            db_path = Path(__file__).parent.parent.parent / "test.db"
            cls._sync_conn = sqlite3.connect(str(db_path))
            cls._sync_conn.row_factory = sqlite3.Row
        return cls._sync_conn

    @classmethod
    async def reset(cls) -> None:
        """Reset the database by clearing all tables."""
        if cls._conn is not None:
            await cls._conn.execute("DELETE FROM transactions")
            await cls._conn.execute("DELETE FROM categories")
            await cls._conn.commit()
        if cls._sync_conn is not None:
            cls._sync_conn.execute("DELETE FROM transactions")
            cls._sync_conn.execute("DELETE FROM categories")
            cls._sync_conn.commit()

    @classmethod
    def seed(cls, sql: str, params: tuple) -> None:
        """Synchronously seed test data using the sync connection."""
        conn = cls._get_sync_conn()
        conn.execute(sql, params)
        conn.commit()


@pytest_asyncio.fixture(autouse=True)
async def reset_db() -> None:
    """Reset database before each test."""
    await TestDB.reset()


@pytest.fixture
def app() -> FastAPI:
    """Create FastAPI app with shared test database."""
    application = FastAPI()
    application.include_router(transactions_router)
    application.include_router(categories_router)
    application.include_router(stats_router)

    from src.api.transactions import get_db as tx_get_db
    from src.api.categories import get_db as cat_get_db
    from src.api.stats import get_db as stats_get_db

    async def get_test_conn() -> aiosqlite.Connection:
        return await TestDB.get_conn()

    application.dependency_overrides[tx_get_db] = get_test_conn
    application.dependency_overrides[cat_get_db] = get_test_conn
    application.dependency_overrides[stats_get_db] = get_test_conn

    return application


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    """Create synchronous TestClient."""
    return TestClient(app)


class TestCategoriesAPI:
    """Tests for GET /api/categories."""

    def test_list_categories_empty(self, client: TestClient) -> None:
        """Should return empty list when no categories exist."""
        response = client.get("/api/categories")
        assert response.status_code == 200
        json = response.json()
        assert json["data"] == []
        assert json["message"] == "OK"

    def test_list_categories_with_data(self, client: TestClient) -> None:
        """Should return categories when they exist."""
        cat_id = str(uuid4())
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )

        response = client.get("/api/categories")
        assert response.status_code == 200
        json = response.json()
        assert len(json["data"]) == 1
        assert json["data"][0]["name"] == "Food"


class TestTransactionsAPI:
    """Tests for transaction endpoints."""

    def test_list_transactions_empty(self, client: TestClient) -> None:
        """Should return empty list when no transactions."""
        response = client.get("/api/transactions")
        assert response.status_code == 200
        assert response.json()["data"] == []

    def test_list_transactions_with_data(self, client: TestClient) -> None:
        """Should return transactions."""
        cat_id = str(uuid4())
        tx_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (tx_id, 5000, cat_id, "Lunch", "2026-04-15", "expense", now),
        )

        response = client.get("/api/transactions")
        assert response.status_code == 200
        data = response.json()["data"]
        assert len(data) == 1
        assert data[0]["amount"] == 5000
        assert data[0]["note"] == "Lunch"

    def test_list_transactions_filter_by_type(self, client: TestClient) -> None:
        """Should filter transactions by type."""
        cat_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 5000, cat_id, "Lunch", "2026-04-15", "expense", now),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 30000, cat_id, "Salary", "2026-04-01", "income", now),
        )

        response = client.get("/api/transactions?type=income")
        assert response.status_code == 200
        data = response.json()["data"]
        assert len(data) == 1
        assert data[0]["type"] == "income"

    def test_list_transactions_filter_by_date_range(self, client: TestClient) -> None:
        """Should filter transactions by date range."""
        cat_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 5000, cat_id, "Lunch", "2026-04-10", "expense", now),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 3000, cat_id, "Dinner", "2026-04-20", "expense", now),
        )

        response = client.get("/api/transactions?start_date=2026-04-15&end_date=2026-04-25")
        assert response.status_code == 200
        data = response.json()["data"]
        assert len(data) == 1
        assert data[0]["note"] == "Dinner"

    def test_list_transactions_filter_by_category(self, client: TestClient) -> None:
        """Should filter transactions by category."""
        cat_id1 = str(uuid4())
        cat_id2 = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id1, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id2, "Transport", "#2196F3", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 5000, cat_id1, "Lunch", "2026-04-15", "expense", now),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 3000, cat_id2, "Taxi", "2026-04-16", "expense", now),
        )

        response = client.get(f"/api/transactions?category_id={cat_id1}")
        assert response.status_code == 200
        data = response.json()["data"]
        assert len(data) == 1
        assert data[0]["note"] == "Lunch"

    def test_create_transaction(self, client: TestClient) -> None:
        """Should create a new transaction."""
        cat_id = str(uuid4())
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )

        response = client.post("/api/transactions", json={
            "amount": 5000,
            "category_id": cat_id,
            "note": "Lunch",
            "date": "2026-04-15",
            "type": "expense",
        })
        assert response.status_code == 200
        json = response.json()
        assert json["message"] == "Transaction created"
        assert json["data"]["amount"] == 5000
        assert json["data"]["note"] == "Lunch"

    def test_create_transaction_invalid_amount(self, client: TestClient) -> None:
        """Should reject transaction with invalid amount."""
        cat_id = str(uuid4())
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )

        response = client.post("/api/transactions", json={
            "amount": -100,
            "category_id": cat_id,
            "note": "Invalid",
            "date": "2026-04-15",
            "type": "expense",
        })
        assert response.status_code == 422

    def test_update_transaction(self, client: TestClient) -> None:
        """Should update an existing transaction."""
        cat_id = str(uuid4())
        tx_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (tx_id, 5000, cat_id, "Lunch", "2026-04-15", "expense", now),
        )

        response = client.put(f"/api/transactions/{tx_id}", json={
            "amount": 6000,
            "note": "Updated Lunch",
        })
        assert response.status_code == 200
        json = response.json()
        assert json["message"] == "Transaction updated"
        assert json["data"]["amount"] == 6000
        assert json["data"]["note"] == "Updated Lunch"

    def test_update_transaction_not_found(self, client: TestClient) -> None:
        """Should return 404 when transaction not found."""
        fake_id = str(uuid4())
        response = client.put(f"/api/transactions/{fake_id}", json={
            "amount": 6000,
        })
        assert response.status_code == 404
        json = response.json()
        assert json["error"] == "Not found"
        assert json["code"] == "TRANSACTION_NOT_FOUND"

    def test_delete_transaction(self, client: TestClient) -> None:
        """Should delete an existing transaction."""
        cat_id = str(uuid4())
        tx_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (tx_id, 5000, cat_id, "Lunch", "2026-04-15", "expense", now),
        )

        response = client.delete(f"/api/transactions/{tx_id}")
        assert response.status_code == 200
        json = response.json()
        assert json["message"] == "Transaction deleted"
        assert json["data"]["id"] == tx_id

    def test_delete_transaction_not_found(self, client: TestClient) -> None:
        """Should return 404 when deleting non-existent transaction."""
        fake_id = str(uuid4())
        response = client.delete(f"/api/transactions/{fake_id}")
        assert response.status_code == 404
        json = response.json()
        assert json["error"] == "Not found"
        assert json["code"] == "TRANSACTION_NOT_FOUND"


class TestStatsAPI:
    """Tests for stats endpoints."""

    def test_monthly_stats_empty(self, client: TestClient) -> None:
        """Should return zeroed stats for empty month."""
        response = client.get("/api/stats/monthly?year=2026&month=4")
        assert response.status_code == 200
        json = response.json()
        assert json["data"]["income"] == 0
        assert json["data"]["expense"] == 0
        assert json["data"]["balance"] == 0

    def test_monthly_stats_with_data(self, client: TestClient) -> None:
        """Should calculate correct monthly stats."""
        cat_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 5000, cat_id, "Lunch", "2026-04-15", "expense", now),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 30000, cat_id, "Salary", "2026-04-01", "income", now),
        )

        response = client.get("/api/stats/monthly?year=2026&month=4")
        assert response.status_code == 200
        json = response.json()
        assert json["data"]["income"] == 30000
        assert json["data"]["expense"] == 5000
        assert json["data"]["balance"] == 25000

    def test_by_category_stats(self, client: TestClient) -> None:
        """Should return breakdown by category."""
        cat_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 5000, cat_id, "Lunch", "2026-04-15", "expense", now),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 30000, cat_id, "Salary", "2026-04-01", "income", now),
        )

        response = client.get("/api/stats/by-category")
        assert response.status_code == 200
        json = response.json()
        assert json["data"]["total_income"] == 30000
        assert json["data"]["total_expense"] == 5000

    def test_by_category_stats_with_date_filter(self, client: TestClient) -> None:
        """Should filter category stats by date range."""
        cat_id = str(uuid4())
        now = datetime.utcnow().isoformat()
        TestDB.seed(
            "INSERT INTO categories (id, name, color, type) VALUES (?, ?, ?, ?)",
            (cat_id, "Food", "#FF9800", "expense"),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 5000, cat_id, "Lunch", "2026-04-10", "expense", now),
        )
        TestDB.seed(
            "INSERT INTO transactions (id, amount, category_id, note, date, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (str(uuid4()), 3000, cat_id, "Dinner", "2026-04-20", "expense", now),
        )

        response = client.get("/api/stats/by-category?start_date=2026-04-15&end_date=2026-04-25")
        assert response.status_code == 200
        json = response.json()
        assert json["data"]["total_expense"] == 3000