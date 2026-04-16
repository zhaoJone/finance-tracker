"""
Transaction service - business logic for transactions.
"""
from datetime import date
from uuid import UUID, uuid4

from pydantic import BaseModel

from src.schemas import Category
from src.repository import CategoryRepository, TransactionRepository


class MonthlySummary(BaseModel):
    """Monthly income/expense summary."""

    year: int
    month: int
    income: int
    expense: int
    balance: int


class CategoryBreakdown(BaseModel):
    """Breakdown of transactions for a single category."""

    category_id: UUID
    category_name: str
    amount: int
    percentage: float


class CategorySummary(BaseModel):
    """Category summary with all breakdowns."""

    categories: list[CategoryBreakdown]
    total_income: int
    total_expense: int


class TransactionService:
    """Business logic for transactions."""

    DEFAULT_CATEGORIES: list[dict[str, str]] = [
        {"name": "Salary", "color": "#4CAF50", "type": "income"},
        {"name": "Food", "color": "#FF9800", "type": "expense"},
        {"name": "Transport", "color": "#2196F3", "type": "expense"},
        {"name": "Entertainment", "color": "#9C27B0", "type": "expense"},
        {"name": "Shopping", "color": "#E91E63", "type": "expense"},
        {"name": "Healthcare", "color": "#F44336", "type": "expense"},
        {"name": "Investment", "color": "#00BCD4", "type": "income"},
        {"name": "Others", "color": "#607D8B", "type": "expense"},
    ]

    def __init__(
        self,
        tx_repo: TransactionRepository,
        category_repo: CategoryRepository,
    ) -> None:
        self._tx_repo = tx_repo
        self._category_repo = category_repo

    async def get_monthly_summary(
        self,
        year: int,
        month: int,
    ) -> MonthlySummary:
        """Return monthly income, expense, and balance."""
        start_date = date(year, month, 1)
        if month == 12:
            end_date = date(year + 1, 1, 1)
        else:
            end_date = date(year, month + 1, 1)

        txs = await self._tx_repo.list(start_date=start_date, end_date=end_date)

        income = sum(tx.amount for tx in txs if tx.type == "income")
        expense = sum(tx.amount for tx in txs if tx.type == "expense")

        return MonthlySummary(
            year=year,
            month=month,
            income=income,
            expense=expense,
            balance=income - expense,
        )

    async def get_category_summary(
        self,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> CategorySummary:
        """Return breakdown by category with amounts and percentages."""
        txs = await self._tx_repo.list(start_date=start_date, end_date=end_date)

        income_map: dict[UUID, int] = {}
        expense_map: dict[UUID, int] = {}

        for tx in txs:
            target = income_map if tx.type == "income" else expense_map
            target[tx.category_id] = target.get(tx.category_id, 0) + tx.amount

        total_income = sum(income_map.values())
        total_expense = sum(expense_map.values())

        categories = await self._category_repo.list()
        cat_map = {cat.id: cat.name for cat in categories}

        breakdowns: list[CategoryBreakdown] = []

        for cat_id, amount in income_map.items():
            pct = (amount / total_income * 100) if total_income else 0.0
            breakdowns.append(
                CategoryBreakdown(
                    category_id=cat_id,
                    category_name=cat_map.get(cat_id, "Unknown"),
                    amount=amount,
                    percentage=round(pct, 2),
                )
            )

        for cat_id, amount in expense_map.items():
            pct = (amount / total_expense * 100) if total_expense else 0.0
            breakdowns.append(
                CategoryBreakdown(
                    category_id=cat_id,
                    category_name=cat_map.get(cat_id, "Unknown"),
                    amount=amount,
                    percentage=round(pct, 2),
                )
            )

        return CategorySummary(
            categories=breakdowns,
            total_income=total_income,
            total_expense=total_expense,
        )

    async def init_default_categories(self) -> list[Category]:
        """Create default categories if none exist. Returns created categories."""
        existing = await self._category_repo.list()
        if existing:
            return existing

        created: list[Category] = []
        for cat_data in self.DEFAULT_CATEGORIES:
            cat = Category(
                id=uuid4(),
                name=cat_data["name"],
                color=cat_data["color"],
                type=cat_data["type"],  # type: ignore[arg-type]
            )
            await self._category_repo.create(cat)
            created.append(cat)

        return created
