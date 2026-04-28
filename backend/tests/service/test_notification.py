"""
Tests for NotificationService.
"""
from datetime import date, datetime
from uuid import UUID, uuid4

import pytest

from src.schemas import Category, Transaction
from src.schemas.notification import ParsedNotification
from src.service.notification import NotificationService


class MockTransactionRepository:
    """Mock for TransactionRepository with find_by_trade_no."""

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

    async def find_by_trade_no(self, trade_no: str, user_id: str) -> Transaction | None:
        for tx in self._txs:
            if tx.trade_no == trade_no and str(tx.user_id) == user_id:
                return tx
        return None

    async def list(
        self,
        user_id: UUID | None = None,
        start_date: date | None = None,
        end_date: date | None = None,
        category_id: UUID | None = None,
        tx_type: str | None = None,
    ) -> list[Transaction]:
        return list(self._txs)

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

    async def list(self, user_id: UUID | None = None) -> list[Category]:
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


class TestNotificationServiceParse:
    """Tests for parse()."""

    def test_parse_alipay_expense(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        result = svc.parse(
            "【支付宝】您有一笔支出，金额¥128.50，收款商家：麦当劳，已完成。28/04 14:32"
        )

        assert result is not None
        assert result.source == "alipay"
        assert result.amount == 12850  # 分
        assert result.type == "expense"
        assert result.counterparty == "麦当劳"

    def test_parse_alipay_income(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        result = svc.parse(
            "【支付宝】您有一笔收入，金额¥50.00，对方：张三，已完成。28/04 14:32"
        )

        assert result is not None
        assert result.source == "alipay"
        assert result.amount == 5000  # 分
        assert result.type == "income"

    def test_parse_wechat_notification(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        result = svc.parse("微信支付，¥58.00，哆来茶，28/04/26 14:32:24支付完成")

        assert result is not None
        assert result.source == "wechat"
        assert result.amount == 5800  # 分
        assert result.counterparty == "哆来茶"

    def test_parse_unknown_returns_none(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        result = svc.parse("这是一条完全无关的短信")

        assert result is None


class TestNotificationServiceMakeDedupKey:
    """Tests for _make_dedup_key()."""

    def test_uses_trade_no_when_present(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        notification = ParsedNotification(
            source="alipay",
            type="income",
            amount=1000,
            counterparty="Test",
            timestamp=datetime(2026, 4, 1, 12, 0, 0),
            trade_no="ALIPAY123456",
            raw_text="",
        )

        key = svc._make_dedup_key(notification)

        assert key == "ALIPAY123456"

    def test_uses_sha256_when_no_trade_no(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        notification = ParsedNotification(
            source="alipay",
            type="income",
            amount=1000,
            counterparty="Test",
            timestamp=datetime(2026, 4, 1, 12, 0, 0),
            trade_no="",
            raw_text="",
        )

        key = svc._make_dedup_key(notification)

        assert len(key) == 32
        assert key.isalnum()


class TestNotificationServiceImportNotifications:
    """Tests for import_notifications()."""

    @pytest.mark.asyncio
    async def test_creates_new_transaction(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        cat = Category(
            id=uuid4(),
            user_id=uuid4(),
            name="Food",
            color="#000000",
            type="expense",
        )
        await cat_repo.create(cat)

        notification = ParsedNotification(
            source="alipay",
            type="expense",
            amount=5000,
            counterparty="KFC",
            timestamp=datetime(2026, 4, 1, 12, 0, 0),
            trade_no="",
            raw_text="",
        )
        user_id = uuid4()

        result = await svc.import_notifications([notification], user_id, cat.id)

        assert result["created"] == 1
        assert result["skipped"] == 0
        assert result["errors"] == []
        assert len(tx_repo._txs) == 1
        assert tx_repo._txs[0].amount == 5000
        assert "[alipay] KFC" in tx_repo._txs[0].note

    @pytest.mark.asyncio
    async def test_skips_duplicate_by_trade_no(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        cat = Category(
            id=uuid4(),
            user_id=uuid4(),
            name="Food",
            color="#000000",
            type="expense",
        )
        await cat_repo.create(cat)

        user_id = uuid4()
        trade_no = "DEDUP123"

        notification1 = ParsedNotification(
            source="alipay",
            type="expense",
            amount=5000,
            counterparty="KFC",
            timestamp=datetime(2026, 4, 1, 12, 0, 0),
            trade_no=trade_no,
            raw_text="",
        )
        notification2 = ParsedNotification(
            source="alipay",
            type="expense",
            amount=5000,
            counterparty="KFC",
            timestamp=datetime(2026, 4, 1, 12, 0, 0),
            trade_no=trade_no,
            raw_text="",
        )

        result1 = await svc.import_notifications([notification1], user_id, cat.id)
        result2 = await svc.import_notifications([notification2], user_id, cat.id)

        assert result1["created"] == 1
        assert result2["skipped"] == 1
        assert len(tx_repo._txs) == 1

    @pytest.mark.asyncio
    async def test_multiple_notifications_mixed_results(self) -> None:
        tx_repo = MockTransactionRepository()
        cat_repo = MockCategoryRepository()
        svc = NotificationService(tx_repo, cat_repo)

        cat = Category(
            id=uuid4(),
            user_id=uuid4(),
            name="Food",
            color="#000000",
            type="expense",
        )
        await cat_repo.create(cat)

        user_id = uuid4()

        notifications = [
            ParsedNotification(
                source="alipay",
                type="expense",
                amount=3000,
                counterparty="KFC",
                timestamp=datetime(2026, 4, 1, 12, 0, 0),
                trade_no="TX001",
                raw_text="",
            ),
            ParsedNotification(
                source="wechat",
                type="expense",
                amount=5000,
                counterparty="KFC",
                timestamp=datetime(2026, 4, 1, 13, 0, 0),
                trade_no="TX002",
                raw_text="",
            ),
            # duplicate of first
            ParsedNotification(
                source="alipay",
                type="expense",
                amount=3000,
                counterparty="KFC",
                timestamp=datetime(2026, 4, 1, 12, 0, 0),
                trade_no="TX001",
                raw_text="",
            ),
        ]

        result = await svc.import_notifications(notifications, user_id, cat.id)

        assert result["created"] == 2
        assert result["skipped"] == 1
        assert result["errors"] == []
        assert len(tx_repo._txs) == 2
