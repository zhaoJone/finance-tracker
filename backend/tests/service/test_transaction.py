"""
Tests for TransactionService.
"""
from datetime import date
from uuid import UUID, uuid4

import pytest

from src.schemas import Category, Transaction
from src.service import (
    CategoryBreakdown,
    CategorySummary,
    MonthlySummary,
    TransactionService,
)


class MockCategoryRepository:
    """Mock for CategoryRepository."""

    def __init__(self) -> None:
        self._categories: list[Category] = []

    async def create(self, category: Category) -> Category:
        self._categories.append(category)
        return category

    async def get(self, id: UUID) -> Category | None:
        for cat in self._categories:
            if cat.id == id:
                return cat
        return None

    async def list(self) -> list[Category]:
        return list(self._categories)

    async def update(self, category: Category) -> Category | None:
        for i, cat in enumerate(self._categories):
            if cat.id == category.id:
                self._categories[i] = category
                return category
        return None

    async def delete(self, id: UUID) -> bool:
        for i, cat in enumerate(self._categories):
            if cat.id == id:
                self._categories.pop(i)
                return True
        return False


class MockTransactionRepository:
    """Mock for TransactionRepository."""

    def __init__(self) -> None:
        self._txs: list[Transaction] = []

    async def create(self, tx: Transaction) -> Transaction:
        self._txs.append(tx)
        return tx

    async def get(self, id: UUID) -> Transaction | None:
        for tx in self._txs:
            if tx.id == id:
                return tx
        return None

    async def list(
        self,
        start_date: date | None = None,
        end_date: date | None = None,
        category_id: UUID | None = None,
        tx_type: str | None = None,
    ) -> list[Transaction]:
        result = list(self._txs)
        if start_date is not None:
            result = [tx for tx in result if tx.date >= start_date]
        if end_date is not None:
            result = [tx for tx in result if tx.date < end_date]
        if category_id is not None:
            result = [tx for tx in result if tx.category_id == category_id]
        if tx_type is not None:
            result = [tx for tx in result if tx.type == tx_type]
        return result

    async def update(self, tx: Transaction) -> Transaction | None:
        for i, t in enumerate(self._txs):
            if t.id == tx.id:
                self._txs[i] = tx
                return tx
        return None

    async def delete(self, id: UUID) -> bool:
        for i, tx in enumerate(self._txs):
            if tx.id == id:
                self._txs.pop(i)
                return True
        return False


def make_tx(
    amount: int,
    tx_type: str,
    cat_id: UUID,
    tx_date: date,
) -> Transaction:
    return Transaction(
        id=uuid4(),
        amount=amount,
        category_id=cat_id,
        note="",
        date=tx_date,
        type=tx_type,  # type: ignore[arg-type]
        created_at=tx_date,
    )


def make_cat(name: str, cat_type: str) -> Category:
    return Category(
        id=uuid4(),
        name=name,
        color="#000000",
        type=cat_type,  # type: ignore[arg-type]
    )


class TestTransactionServiceGetMonthlySummary:
    """Tests for get_monthly_summary."""

    @pytest.mark.asyncio
    async def test_empty_month(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        result = await svc.get_monthly_summary(2026, 3)

        assert result.year == 2026
        assert result.month == 3
        assert result.income == 0
        assert result.expense == 0
        assert result.balance == 0

    @pytest.mark.asyncio
    async def test_income_and_expense(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        cat_income = make_cat("Salary", "income")
        cat_expense = make_cat("Food", "expense")
        await cat_repo.create(cat_income)
        await cat_repo.create(cat_expense)

        await tx_repo.create(make_tx(50000, "income", cat_income.id, date(2026, 3, 15)))
        await tx_repo.create(make_tx(15000, "expense", cat_expense.id, date(2026, 3, 20)))

        result = await svc.get_monthly_summary(2026, 3)

        assert result.income == 50000
        assert result.expense == 15000
        assert result.balance == 35000

    @pytest.mark.asyncio
    async def test_only_expense(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        cat_expense = make_cat("Food", "expense")
        await cat_repo.create(cat_expense)

        await tx_repo.create(make_tx(3000, "expense", cat_expense.id, date(2026, 4, 10)))

        result = await svc.get_monthly_summary(2026, 4)

        assert result.income == 0
        assert result.expense == 3000
        assert result.balance == -3000


class TestTransactionServiceGetCategorySummary:
    """Tests for get_category_summary."""

    @pytest.mark.asyncio
    async def test_empty(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        result = await svc.get_category_summary()

        assert result.total_income == 0
        assert result.total_expense == 0
        assert result.categories == []

    @pytest.mark.asyncio
    async def test_single_category(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        cat = make_cat("Salary", "income")
        await cat_repo.create(cat)

        await tx_repo.create(make_tx(10000, "income", cat.id, date(2026, 1, 1)))
        await tx_repo.create(make_tx(10000, "income", cat.id, date(2026, 1, 2)))

        result = await svc.get_category_summary()

        assert result.total_income == 20000
        assert result.total_expense == 0
        assert len(result.categories) == 1
        assert result.categories[0].amount == 20000
        assert result.categories[0].percentage == 100.0

    @pytest.mark.asyncio
    async def test_percentage_calculation(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        cat1 = make_cat("Salary", "income")
        cat2 = make_cat("Bonus", "income")
        await cat_repo.create(cat1)
        await cat_repo.create(cat2)

        await tx_repo.create(make_tx(70000, "income", cat1.id, date(2026, 1, 1)))
        await tx_repo.create(make_tx(30000, "income", cat2.id, date(2026, 1, 2)))

        result = await svc.get_category_summary()

        assert result.total_income == 100000
        income_breakdowns = [c for c in result.categories if c.amount == 70000]
        assert income_breakdowns[0].percentage == 70.0
        bonus_breakdowns = [c for c in result.categories if c.amount == 30000]
        assert bonus_breakdowns[0].percentage == 30.0


class TestTransactionServiceInitDefaultCategories:
    """Tests for init_default_categories."""

    @pytest.mark.asyncio
    async def test_no_existing_categories(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        result = await svc.init_default_categories()

        assert len(result) == 8
        names = {cat.name for cat in result}
        assert "Salary" in names
        assert "Food" in names

    @pytest.mark.asyncio
    async def test_existing_categories_unchanged(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = TransactionService(tx_repo, cat_repo)

        existing = make_cat("My Custom Category", "expense")
        await cat_repo.create(existing)

        result = await svc.init_default_categories()

        assert len(result) == 1
        assert result[0].name == "My Custom Category"
