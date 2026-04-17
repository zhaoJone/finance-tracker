"""
Tests for API routes using TestClient.
"""
import os
import tempfile
import sqlite3
from datetime import datetime
from uuid import uuid4

import pytest
import pytest_asyncio
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from src.repository.models import Base


class TestDB:
    """Shared test database using SQLAlchemy async with SQLite file."""

    _engine = None
    _session_factory = None
    _sync_conn: sqlite3.Connection | None = None
    _db_path: str | None = None

    @classmethod
    def get_db_path(cls) -> str:
        """Get or create temp database file path."""
        if cls._db_path is None:
            fd, cls._db_path = tempfile.mkstemp(suffix=".db")
            os.close(fd)
        return cls._db_path

    @classmethod
    def get_engine(cls):
        """Get or create the async engine."""
        if cls._engine is None:
            db_path = cls.get_db_path()
            cls._engine = create_async_engine(
                f"sqlite+aiosqlite:///{db_path}",
                connect_args={"check_same_thread": False},
            )
        return cls._engine

    @classmethod
    def get_session_factory(cls):
        """Get or create the session factory."""
        if cls._session_factory is None:
            cls._session_factory = async_sessionmaker(
                bind=cls.get_engine(),
                class_=AsyncSession,
                expire_on_commit=False,
            )
        return cls._session_factory

    @classmethod
    def get_sync_conn(cls) -> sqlite3.Connection:
        """Get synchronous connection for test seeding."""
        if cls._sync_conn is None:
            cls._sync_conn = sqlite3.connect(cls.get_db_path(), check_same_thread=False)
            cls._sync_conn.row_factory = sqlite3.Row
        return cls._sync_conn

    @classmethod
    async def setup_db(cls) -> None:
        """Create tables."""
        engine = cls.get_engine()
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    @classmethod
    async def reset(cls) -> None:
        """Clear all tables."""
        factory = cls.get_session_factory()
        async with factory() as session:
            await session.execute(text("DELETE FROM transactions"))
            await session.execute(text("DELETE FROM categories"))
            await session.commit()

    @classmethod
    def seed(cls, sql: str, params: tuple) -> None:
        """Synchronously seed test data using the sync connection."""
        conn = cls.get_sync_conn()
        conn.execute(sql, params)
        conn.commit()

    @classmethod
    def cleanup(cls) -> None:
        """Close connections and remove temp file."""
        if cls._sync_conn:
            cls._sync_conn.close()
            cls._sync_conn = None
        if cls._engine:
            cls._engine = None
            cls._engine_sync = None
        if cls._db_path and os.path.exists(cls._db_path):
            os.unlink(cls._db_path)
            cls._db_path = None


@pytest_asyncio.fixture(scope="function", autouse=True)
async def setup_test_db():
    """Setup test database once per test function."""
    await TestDB.setup_db()
    await TestDB.reset()
    yield
    await TestDB.reset()


@pytest.fixture
def app() -> FastAPI:
    """Create FastAPI app with shared test database."""
    from src.api.categories import router as categories_router
    from src.api.stats import router as stats_router
    from src.api.transactions import router as transactions_router
    from src.config.database import get_db

    application = FastAPI()
    application.include_router(transactions_router)
    application.include_router(categories_router)
    application.include_router(stats_router)

    async def get_test_session():
        """Get test SQLAlchemy session."""
        factory = TestDB.get_session_factory()
        async with factory() as session:
            yield session

    application.dependency_overrides[get_db] = get_test_session

    return application


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    """Create synchronous TestClient."""
    return TestClient(app)


class TestCategoriesAPI:
    """Tests for GET /api/categories."""

    def test_list_categories_empty(self, client: TestClient) -> None:
        """Should return empty dict when no categories exist."""
        response = client.get("/api/categories")
        assert response.status_code == 200
        json = response.json()
        assert json["data"] == {"income": [], "expense": []}
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
        assert len(json["data"]["expense"]) == 1
        assert json["data"]["expense"][0]["name"] == "Food"


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
